use petgraph::{
    algo::dominators,
    graph::{DiGraph, NodeIndex},
    visit::DfsPostOrder,
};
use std::{
    collections::{HashMap, hash_map::Entry},
    ops::Deref,
    path::{Path, PathBuf},
};

use crate::cache::{GcRootClosure, PathInfo};

#[derive(Default)]
pub struct StoreGraph {
    graph: DiGraph<Node, ()>,
    nodes: HashMap<PathBuf, NodeIndex>,
    nodes_by_index: HashMap<NodeIndex, PathBuf>,
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
            nodes: HashMap::new(),
            nodes_by_index: HashMap::new(),
        };
        for root in roots {
            graph.add_parents(&root.symlink);
            graph.add_closure(root);
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

    fn add_closure(&mut self, root: &GcRootClosure) {
        let referrer = self.add_node(&root.symlink, Node::path());

        let mut stack = vec![(*referrer, &root.store_path)];
        while let Some((referrer, store_path)) = stack.pop() {
            let path_info = &root.path_info[store_path]; // TODO: don't panic?

            let reference = self.add_node(store_path, Node::store_path(path_info));
            self.add_edge(referrer, *reference);

            if let NodeEntry::Inserted(reference) = reference {
                for store_path in &path_info.references {
                    stack.push((reference, store_path.deref()));
                }
            }
        }
    }

    fn compute_dominators(&mut self) -> DominatorGraph {
        let root = *self.add_node("/", Node::path());

        let dominators = dominators::simple_fast(&self.graph, root);
        let mut dfs = DfsPostOrder::new(&self.graph, root);
        while let Some(node) = dfs.next(&self.graph) {
            let total_size = self
                .graph
                .neighbors(node)
                // TODO: error if missing
                .flat_map(|reference| Some(self.graph.node_weight(reference)?.closure_size))
                .sum();
            // TODO: error if missing
            let Some(node_weight) = self.graph.node_weight_mut(node) else {
                continue;
            };
            node_weight.closure_size = total_size;
            if let Some(dominator) = dominators.immediate_dominator(node) {
                // TODO: error if missing
                let retained = node_weight.added_size;
                // TODO: error if missing
                let Some(dominator) = self.graph.node_weight_mut(dominator) else {
                    continue;
                };
                dominator.added_size += retained;
            }
        }

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

impl Node {
    fn path() -> Self {
        Self {
            ty: NodeType::Path,
            added_size: 0,
            closure_size: 0,
        }
    }

    fn store_path(path_info: &PathInfo) -> Self {
        Self {
            ty: NodeType::StorePath,
            added_size: path_info.nar_size,
            closure_size: path_info.nar_size,
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
    use std::{fmt::Display, sync::Arc, time::SystemTime};

    use petgraph::dot::Dot;

    use crate::{cache::PathInfoMap, nix::GcRoot, types::StorePath};

    use super::*;

    #[test]
    fn sizes() {
        let mut store = StoreBuilder::new();
        let a = store.path_info("/store/a", 100, []);
        let b = store.path_info("/store/b", 10, [a]);
        let c = store.path_info("/store/c", 20, [a]);
        let store = store.build();

        let roots = vec![
            store.root("/gcroots/b", b), //
            store.root("/gcroots/c", c),
        ];
        let store_graph = StoreGraph::build(&roots);
        insta::assert_snapshot!(Dot::new(&store_graph), @r#"
        digraph {
            0 [ label = "/gcroots/b       (closure =   0, added =  10)" ]
            1 [ label = "/gcroots         (closure =   0, added = 130)" ]
            2 [ label = "/                (closure =   0, added = 130)" ]
            3 [ label = "/gcroots/c       (closure =   0, added =  20)" ]
            1 -> 0 [ label = "" ]
            2 -> 1 [ label = "" ]
            1 -> 3 [ label = "" ]
        }
        "#)
    }

    type StorePathId = usize;

    #[derive(Default)]
    struct StoreBuilder<T> {
        next_id: StorePathId,
        by_id: HashMap<StorePathId, StorePath>,
        by_path: T,
    }

    impl StoreBuilder<PathInfoMap> {
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
            assert!(!self.by_path.contains_key(&path), "Duplicate path {path:?}");

            let id = self.by_id.len();
            self.by_id.insert(id, path.clone());
            self.by_path.insert(
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

        fn build(self) -> StoreBuilder<Arc<PathInfoMap>> {
            let Self {
                next_id,
                by_id,
                by_path,
            } = self;
            StoreBuilder {
                next_id,
                by_id,
                by_path: Arc::new(by_path),
            }
        }
    }

    impl StoreBuilder<Arc<PathInfoMap>> {
        fn root(&self, symlink: impl Into<PathBuf>, store_path: StorePathId) -> GcRootClosure {
            GcRootClosure {
                root: GcRoot {
                    symlink: symlink.into(),
                    modified: SystemTime::UNIX_EPOCH,
                    store_path: self.by_id[&store_path].deref().clone(),
                },
                path_info: self.by_path.clone(),
            }
        }
    }

    impl Display for Dominator {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            write!(
                f,
                "{:<16} (closure = {:>3}, added = {:>3})",
                self.path.to_string_lossy(),
                self.closure_size,
                self.added_size
            )
        }
    }
}
