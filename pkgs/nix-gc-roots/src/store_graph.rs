use fixedbitset::FixedBitSet;
use petgraph::{
    algo::dominators::{self, Dominators},
    graph::{DiGraph, NodeIndex},
};
use rkyv::ser::allocator::{Arena, ArenaHandle};
use rustc_hash::FxHashMap;
use std::{
    collections::hash_map::Entry,
    ops::Deref,
    path::{Path, PathBuf},
    rc::Rc,
};

use crate::{
    cache::{ArchivedPathInfo, GcRootClosure},
    types::{ArchivedBytes, StorePath},
};

#[derive(Default)]
pub struct StoreGraph {
    graph: DiGraph<Node, ()>,
    nodes: FxHashMap<PathBuf, NodeIndex>,
    nodes_by_index: FxHashMap<NodeIndex, PathBuf>,
}

#[derive(Clone, Copy, Debug)]
struct Node {
    ty: NodeType,
    added_size: u64,
    closure_size: u64,
}

#[derive(Clone, Copy, Debug)]
enum NodeType {
    Path,
    StorePath,
}

impl StoreGraph {
    pub fn build(roots: &[GcRootClosure]) -> DominatorGraph {
        let mut graph = Self {
            graph: DiGraph::new(),
            nodes: FxHashMap::default(),
            nodes_by_index: FxHashMap::default(),
        };
        let mut arena = Arena::new();
        for root in roots {
            graph.add_parents(&root.symlink);
            graph.add_closure(root, arena.acquire());
        }
        graph.compute_dominators()
    }

    fn add_parents(&mut self, mut path: &Path) {
        let mut path_index = self.add_node(path, Node::path());
        while let Some(parent) = path.parent()
            && let NodeEntry::Inserted(index) = path_index
        {
            let parent_index = self.add_node(parent, Node::path());
            self.add_edge(*parent_index, index);
            path = parent;
            path_index = parent_index;
        }
    }

    fn add_closure(&mut self, root: &GcRootClosure, alloc: ArenaHandle) {
        let referrer = self.add_node(&root.symlink, Node::path());

        let root_store_path = archived_path(&root.store_path, alloc);
        let mut stack = vec![(*referrer, &*root_store_path)];
        while let Some((referrer, store_path)) = stack.pop() {
            let Some(path_info) = &root.closure.0.get(store_path) else {
                let mut paths = root
                    .closure
                    .0
                    .keys()
                    .map(|k| format!(" - {k:?}: {}", k == store_path))
                    .collect::<Vec<_>>();
                paths.sort_unstable();
                panic!(
                    "Closure missing store path\n   {:#?}:\n{}",
                    store_path,
                    paths.join("\n")
                )
            };

            let reference = self.add_node(store_path.to_path_buf(), Node::store_path(path_info));
            self.add_edge(referrer, *reference);

            if let NodeEntry::Inserted(reference) = reference {
                for store_path in path_info.references.iter() {
                    stack.push((reference, store_path));
                }
            }
        }
    }

    fn compute_dominators(&mut self) -> DominatorGraph {
        let root = *self.add_node("/", Node::path());
        let dominators = dominators::simple_fast(&self.graph, root);

        fn compute_sizes(
            // TODO: vec
            visited: &mut FxHashMap<NodeIndex, Rc<FixedBitSet>>,
            dominators: &Dominators<NodeIndex>,
            graph: &mut DiGraph<Node, ()>,
            index: NodeIndex,
        ) -> Rc<FixedBitSet> {
            if let Some(reachability) = visited.get(&index) {
                return reachability.clone(); // TODO
            }
            visited.insert(index, Rc::new(FixedBitSet::new()));

            let node = graph[index];
            let neighbors = graph.neighbors(index).collect::<Vec<_>>();

            let mut reachability = FixedBitSet::with_capacity(graph.node_count());
            for neighbor in neighbors {
                if matches!(node.ty, NodeType::StorePath) {
                    reachability.insert(neighbor.index());
                }
                reachability |= &*compute_sizes(visited, dominators, graph, neighbor);
            }

            graph[index].closure_size += reachability
                .ones()
                .map(|i| graph[NodeIndex::new(i)].added_size)
                .sum::<u64>();

            // TODO: error if missing
            for dominator in dominators.dominators(index).into_iter().flatten() {
                graph[dominator].added_size += node.added_size;
            }

            let reachability = Rc::new(reachability);
            visited.insert(index, reachability.clone());
            reachability
        }

        // let mut dfs = DfsPostOrder::new(&self.graph, root);
        // while let Some(node) = dfs.next(&self.graph) {
        //     let total_size = self
        //         .graph
        //         .neighbors(node)
        //         // TODO: error if missing
        //         .flat_map(|reference| Some(self.graph.node_weight(reference)?.closure_size))
        //         .sum();
        //     // TODO: error if missing
        //     let Some(node_weight) = self.graph.node_weight_mut(node) else {
        //         continue;
        //     };
        //     node_weight.closure_size = total_size;
        //     if let Some(dominator) = dominators.immediate_dominator(node) {
        //         // TODO: error if missing
        //         let retained = node_weight.added_size;
        //         // TODO: error if missing
        //         let Some(dominator) = self.graph.node_weight_mut(dominator) else {
        //             continue;
        //         };
        //         dominator.closure_size += total_size;
        //         dominator.added_size += retained;
        //     }
        // }

        compute_sizes(
            &mut FxHashMap::with_capacity_and_hasher(self.graph.node_count(), Default::default()),
            &dominators,
            &mut self.graph,
            root,
        );

        self.graph.filter_map(
            |ni, n| {
                matches!(n.ty, NodeType::Path).then_some(Dominator {
                    path: self.nodes_by_index[&ni].clone(),
                    added_size: n.added_size,
                    closure_size: n.closure_size,
                })
            },
            |_, _| Some(""),
        )
    }

    fn add_node(&mut self, path: impl Into<PathBuf>, node: Node) -> NodeEntry {
        let path = path.into();
        match self.nodes.entry(path.clone()) {
            Entry::Occupied(entry) => NodeEntry::Existing(*entry.get()),
            Entry::Vacant(entry) => {
                let index = *entry.insert_entry(self.graph.add_node(node)).get();
                self.nodes_by_index.insert(index, path);
                NodeEntry::Inserted(index)
            }
        }
    }

    fn add_edge(&mut self, from: NodeIndex, to: NodeIndex) {
        self.graph.add_edge(from, to, ());
    }
}

fn archived_path(
    path: impl Into<StorePath>,
    alloc: ArenaHandle,
) -> ArchivedBytes<'static, StorePath> {
    ArchivedBytes::from_value(&path.into(), alloc).expect("Failed to serialize store_path")
}

impl Node {
    fn path() -> Self {
        Self {
            ty: NodeType::Path,
            added_size: 0,
            closure_size: 0,
        }
    }

    fn store_path(path_info: &ArchivedPathInfo) -> Self {
        Self {
            ty: NodeType::StorePath,
            added_size: path_info.nar_size.into(),
            closure_size: path_info.nar_size.into(),
        }
    }
}

#[derive(Clone, Copy)]
enum NodeEntry {
    Inserted(NodeIndex),
    Existing(NodeIndex),
}

impl Deref for NodeEntry {
    type Target = NodeIndex;

    fn deref(&self) -> &Self::Target {
        let (NodeEntry::Inserted(index) | NodeEntry::Existing(index)) = &self;
        index
    }
}

pub type DominatorGraph = DiGraph<Dominator, &'static str>;

#[derive(Debug, Clone)]
pub struct Dominator {
    pub path: PathBuf,
    pub added_size: u64,
    pub closure_size: u64,
}

#[cfg(test)]
mod tests {
    use std::{fmt::Display, time::SystemTime};

    use petgraph::dot::Dot;

    use crate::{
        cache::{ArchivedClosure, Closure, PathInfo},
        nix::GcRoot,
        types::{Aligned, StorePath},
    };

    use super::*;

    #[test]
    fn sizes() {
        let mut store = StoreBuilder::new();
        let a = store.path_info("/store/a", 100, []);
        let b = store.path_info("/store/b", 50, []);
        let c = store.path_info("/store/c", 20, [b]);
        let system = store.path_info("/store/system", 10, [a]);
        let profile = store.path_info("/store/profile", 5, [b]);
        let store = store.build();

        let roots = vec![
            store.root("/run/current/sw", system), //
            store.root("/home/user/.nix-profile", profile),
            store.root("/tmp/c", c),
        ];
        let store_graph = StoreGraph::build(&roots);
        insta::assert_snapshot!(Dot::new(&store_graph), @r#"
        digraph {
            0 [ label = "/run/current/sw          (closure = 200, added = 110)" ]
            1 [ label = "/run/current             (closure = 200, added = 110)" ]
            2 [ label = "/run                     (closure = 200, added = 110)" ]
            3 [ label = "/                        (closure = 300, added = 185)" ]
            4 [ label = "/home/user/.nix-profile  (closure = 100, added =   5)" ]
            5 [ label = "/home/user               (closure = 100, added =   5)" ]
            6 [ label = "/home                    (closure = 100, added =   5)" ]
            7 [ label = "/tmp/c                   (closure = 100, added =  20)" ]
            8 [ label = "/tmp                     (closure = 100, added =  20)" ]
            1 -> 0 [ label = "" ]
            2 -> 1 [ label = "" ]
            3 -> 2 [ label = "" ]
            5 -> 4 [ label = "" ]
            6 -> 5 [ label = "" ]
            3 -> 6 [ label = "" ]
            8 -> 7 [ label = "" ]
            3 -> 8 [ label = "" ]
        }
        "#)
    }

    type StorePathId = usize;

    #[derive(Default)]
    struct StoreBuilder<T> {
        next_id: StorePathId,
        by_id: FxHashMap<StorePathId, StorePath>,
        closure: T,
    }

    impl StoreBuilder<Closure> {
        fn new() -> Self {
            Self::default()
        }

        fn path_info(
            &mut self,
            path: impl Into<StorePath>,
            nar_size: u64,
            references: impl IntoIterator<Item = StorePathId>,
        ) -> StorePathId {
            let path = path.into();
            assert!(!self.closure.contains_key(&path), "Duplicate path {path:?}");

            let id = self.by_id.len();
            self.by_id.insert(id, path.clone());
            self.closure.insert(
                path,
                PathInfo {
                    nar_size,
                    references: references
                        .into_iter()
                        .map(|id| self.by_id[&id].clone())
                        .collect(),
                },
            );
            id
        }

        fn build(self) -> StoreBuilder<ArchivedClosure<'static>> {
            let Self {
                next_id,
                by_id,
                closure,
            } = self;
            let mut arena = Arena::new();
            let archived = ArchivedBytes::from_value(&Aligned(closure), arena.acquire())
                .expect("Failed to archive closure");
            StoreBuilder {
                next_id,
                by_id,
                closure: archived,
            }
        }
    }

    impl StoreBuilder<ArchivedClosure<'static>> {
        fn root(
            &self,
            symlink: impl Into<PathBuf>,
            store_path: StorePathId,
        ) -> GcRootClosure<'static> {
            GcRootClosure {
                root: GcRoot {
                    symlink: symlink.into(),
                    modified: SystemTime::UNIX_EPOCH,
                    store_path: self.by_id[&store_path].deref().clone(),
                },
                closure: self.closure.clone(),
            }
        }
    }

    impl Display for Dominator {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            write!(
                f,
                "{:<24} (closure = {:>3}, added = {:>3})",
                self.path.to_string_lossy(),
                self.closure_size,
                self.added_size
            )
        }
    }
}
