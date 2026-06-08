mod app;
mod cache;
mod components;
mod model;
mod msg;
mod nix;
mod types;

use anyhow::Result;
use app::Model;
use petgraph::graph::{DiGraph, NodeIndex};
use std::{
    collections::HashMap,
    env,
    path::PathBuf,
    time::{Duration, Instant},
};
use tuirealm::application::PollStrategy;

use crate::cache::Cache;

fn perf() -> Result<()> {
    let start = Instant::now();
    eprintln!("[{:>12?}] Find gc roots...", Duration::from_secs(0));
    let roots = nix::gc_roots()?;

    eprintln!("[{:?}] Lookup PathInfo...", start.elapsed());
    let cache = Cache::new(&PathBuf::from("/home/nregner/.cache/nix-gc-roots"))?;
    let roots = cache.build_graph(roots)?;

    eprintln!("[{:?}] Build graph...", start.elapsed());
    let mut graph = DiGraph::<(), ()>::new();
    let mut nodes = HashMap::<PathBuf, NodeIndex>::new();

    macro_rules! node_id {
        ($path:expr) => {
            *nodes
                .entry($path.to_owned())
                .or_insert_with(|| graph.add_node(()))
        };
    }

    for root in &roots {
        // TODO: just store Path
        let path_node = node_id!(root.symlink);
        let store_node = node_id!(root.store_path);
        graph.add_edge(path_node, store_node, ());

        for (path, _path_info) in root.path_info.iter() {
            let dep_node = node_id!(path.to_path_buf());
            graph.add_edge(store_node, dep_node, ());
        }
    }
    dbg!(graph.node_count());
    dbg!(graph.edge_count());

    eprintln!("[{:?}] Done...", start.elapsed());
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
