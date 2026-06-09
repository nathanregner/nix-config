mod app;
mod cache;
mod components;
mod model;
mod msg;
mod nix;
mod types;

use anyhow::Result;
use app::Model;
use petgraph::{
    algo::dominators,
    graph::{DiGraph, NodeIndex},
    visit::DfsPostOrder,
};
use std::{
    collections::HashMap,
    env,
    ops::{ControlFlow, Deref},
    path::PathBuf,
    time::{Duration, Instant},
};
use tuirealm::application::PollStrategy;

use crate::{
    cache::{Cache, PathInfo},
    nix::GcRoot,
};

#[derive(Default)]
struct StoreGraph {
    graph: DiGraph<Node, ()>,
    nodes: HashMap<PathBuf, NodeIndex>,
}

#[derive(Clone, Copy)]
struct Node {
    ty: NodeType,
    added_size: u64,
    closure_size: u64,
}

#[derive(Clone, Copy)]
enum NodeType {
    Path,
    StorePath,
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
            ty: NodeType::Path,
            added_size: path_info.nar_size,
            closure_size: path_info.nar_size,
        }
    }
}

impl StoreGraph {
    pub fn add_node(&mut self, path: impl Into<PathBuf>, node: Node) -> NodeIndex {
        *self
            .nodes
            .entry(path.into())
            .or_insert_with(|| self.graph.add_node(node))
    }

    pub fn add_edge(&mut self, from: NodeIndex, to: NodeIndex) {
        self.graph.add_edge(from, to, ());
    }
}

pub struct PathTree {
    path: PathBuf,
    added_size: u64,
    closure_size: u64,
    children: Vec<PathTree>,
}

impl PathTree {
    pub fn new(root: GcRoot, added_size: u64, closure_size: u64) -> Self {
        Self {
            root,
            added_size,
            closure_size,
        }
    }
}

impl Deref for PathTree {
    type Target = GcRoot;

    fn deref(&self) -> &Self::Target {
        &self.root
    }
}

fn perf() -> Result<()> {
    let start = Instant::now();
    eprintln!("[{:>12?}] Find gc roots...", Duration::from_secs(0));
    let roots = nix::gc_roots()?;

    eprintln!("[{:?}] Lookup PathInfo...", start.elapsed());
    let cache = Cache::new(&PathBuf::from("/home/nregner/.cache/nix-gc-roots"))?;
    let roots = cache.get_path_info(roots)?;

    eprintln!("[{:?}] Build graph...", start.elapsed());
    let mut graph = StoreGraph::default();

    for root in &roots {
        let referrer = graph.add_node(&root.symlink, Node::path());

        let mut stack = vec![(referrer, &root.store_path)];
        while let Some((referrer, store_path)) = stack.pop() {
            //
            let path_info = &root.path_info[store_path]; // TODO: don't panic?

            let lookup = match graph.nodes.get(store_path) {
                Some(reference) => ControlFlow::Break(*reference),
                None => {
                    ControlFlow::Continue(graph.add_node(store_path, Node::store_path(path_info)))
                }
            };

            let reference = match lookup {
                ControlFlow::Continue(r) | ControlFlow::Break(r) => r,
            };
            graph.add_edge(referrer, reference);

            if lookup.is_continue() {
                for store_path in &path_info.references {
                    stack.push((reference, store_path.deref()));
                }
            }
        }
    }
    dbg!(graph.graph.node_count());
    dbg!(graph.graph.edge_count());
    eprintln!("[{:?}] Find dominators...", start.elapsed());
    let root = graph.add_node("/", Node::path());
    let dominators = dominators::simple_fast(&graph.graph, root);

    let mut dfs = DfsPostOrder::new(&graph.graph, root);
    while let Some(node) = dfs.next(&graph.graph) {
        let total_size = graph
            .graph
            .neighbors(node)
            // TODO: error if missing
            .flat_map(|reference| Some(graph.graph.node_weight(reference)?.closure_size))
            .sum();
        // TODO: error if missing
        let Some(node_weight) = graph.graph.node_weight_mut(node) else {
            continue;
        };
        node_weight.closure_size = total_size;
        if let Some(dominator) = dominators.immediate_dominator(node) {
            // TODO: error if missing
            let retained = node_weight.added_size;
            // TODO: error if missing
            let Some(dominator) = graph.graph.node_weight_mut(dominator) else {
                continue;
            };
            dominator.added_size += retained;
        }
    }

    let tree = PathTree::eprintln!("[{:?}] Done...", start.elapsed());
    Ok(())
}

fn main() -> Result<()> {
    if env::args().len() > 1 {
        return perf();
    }

    let mut model = Model::default();

    model.view();
    model.load_roots()?;
    model.view();

    while !model.quit {
        let messages = model.app.tick(PollStrategy::BlockCollectUpTo(10))?;
        for msg in messages {
            model.update(msg);
        }
        model.view();
    }

    Ok(())
}
