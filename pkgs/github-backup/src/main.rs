#![feature(let_chains)]

use color_eyre::eyre;

mod gitea;
mod github;
mod sync;
mod update_access_token;

fn main() -> eyre::Result<()> {
    color_eyre::install()?;
    tracing_subscriber::fmt::init();
    // config::update_mirrors("/tmp".into(), "bogus")?;
    tracing::info!("test");
    Ok(())
}
