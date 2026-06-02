mod app;
mod cache;
mod components;
mod model;
mod msg;
mod nix;
mod radix_tree;

use anyhow::Result;
use app::Model;
use petgraph::graph::{DiGraph, NodeIndex};
use std::{
    collections::HashMap,
    env,
    path::{Path, PathBuf},
    time::{Duration, Instant},
};
use tuirealm::application::PollStrategy;

use crate::{cache::Cache, nix::PathInfo};

fn perf() -> Result<()> {
    let start = Instant::now();

    eprintln!("[{:>12?}] Find gc roots...", Duration::from_secs(0));
    let roots = nix::gc_roots()?;

    eprintln!("[{:?}] Lookup PathInfo...", start.elapsed());
    let cache = Cache::new(&PathBuf::from("/home/nregner/.cache/nix-gc-roots"))?;
    let roots = cache.build_graph(roots)?;

    eprintln!("[{:?}] Build graph...", start.elapsed());
    let mut graph = DiGraph::<Option<&PathInfo>, ()>::new();
    let mut nodes = HashMap::<&Path, NodeIndex>::new();
    macro_rules! node_id {
        ($path:expr, $path_info:expr) => {
            *nodes
                .entry($path)
                .or_insert_with(|| graph.add_node($path_info))
        };
    }

    for root in &roots {
        let path_node = node_id!(&root.symlink, None);
        let store_node = node_id!(&root.store_path, None);
        graph.add_edge(path_node, store_node, ());

        for (path, path_info) in root.path_info.iter() {
            let dep_node = node_id!(path, Some(path_info));
            graph.add_edge(store_node, dep_node, ());
        }

        let mut path = root.symlink.as_path();
        let mut path_node = path_node;
        while let Some(parent) = path.parent() {
            let parent_node = node_id!(parent, None);
            graph.add_edge(path_node, parent_node, ());
            path = parent;
            path_node = parent_node;
        }
    }
    dbg!(graph.node_count());
    dbg!(graph.edge_count());

    // let mut graph = DiGraphMap::new();
    // let mut stack = vec![(None, &trie.subtrie(key))];
    // while let Some((parent_path, node)) = stack.pop() {
    //     for child in node.children() {
    //         stack.push((None, child));
    //     }
    //
    //     if let (Some(path), Some(root)) = (node.key(), node.value()) {
    //         if let Some(parent_path) = parent_path {
    //             graph.add_edge(parent_path, root.store_path.clone(), ());
    //         }
    //
    //         // graph.add_node(path, root);
    //         // graph.insert(path, root);
    //     }
    // }

    eprintln!("[{:?}] Done...", start.elapsed());
    // let roots = cache.get_sizes(roots)?;
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
