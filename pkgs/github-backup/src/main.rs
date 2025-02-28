#![feature(let_chains)]

use color_eyre::eyre;
use figment::{providers::Env, Figment};
use serde::Deserialize;

mod gitea;
mod github;
mod sync;
mod update_access_token;

#[derive(Deserialize)]
struct Config {
    github_token: String,
    gitea_token: String,
}

#[tokio::main]
async fn main() -> eyre::Result<()> {
    color_eyre::install()?;
    tracing_subscriber::fmt::init();

    let config = Figment::new().merge(Env::raw()).extract::<Config>()?;

    let github = github::Client::new(config.github_token.to_string())?;
    let gitea = gitea::Client::new(
        "https://git.nregner.net",
        config.gitea_token,
        config.github_token,
    )?;

    sync::sync_repos(&github, &gitea).await?;

    // config::update_mirrors("/tmp".into(), "bogus")?;
    tracing::info!("test");
    Ok(())
}
