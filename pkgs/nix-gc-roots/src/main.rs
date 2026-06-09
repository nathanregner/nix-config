mod app;
mod cache;
mod components;
mod model;
mod msg;
mod nix;
mod store_graph;
mod types;

use anyhow::Result;
use app::Model;
use petgraph::dot::Dot;
use std::{
    env,
    path::PathBuf,
    time::{Duration, Instant},
};
use tuirealm::application::PollStrategy;

use crate::{cache::Cache, store_graph::StoreGraph};

fn perf() -> Result<()> {
    let start = Instant::now();
    eprintln!("[{:>12?}] Find gc roots...", Duration::from_secs(0));
    let roots = nix::gc_roots()?;

    eprintln!("[{:?}] Lookup PathInfo...", start.elapsed());
    let cache = Cache::new(&PathBuf::from("/home/nregner/.cache/nix-gc-roots"))?;
    let roots = cache.get_path_info(roots)?;

    eprintln!("[{:?}] Build graph...", start.elapsed());
    let dominators = StoreGraph::build(&roots);
    eprintln!("[{:?}] Done...", start.elapsed());
    println!("{:?}", Dot::new(&dominators));
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
