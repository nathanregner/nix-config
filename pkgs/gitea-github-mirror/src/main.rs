#![feature(let_chains)]

use clap::{Parser, Subcommand};
use color_eyre::eyre;
use figment::{providers::Env, Figment};
use serde::Deserialize;

mod access_token;
mod gitea;
mod github;
mod sync;

#[derive(Deserialize)]
struct Config {
    github_token: String,
    gitea_token: String,
}

#[derive(Parser, Clone, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand, Clone, Debug)]
enum Commands {
    Sync,
    UpdateAccessToken,
}

#[tokio::main]
async fn main() -> eyre::Result<()> {
    color_eyre::install()?;
    tracing_subscriber::fmt::init();

    let args = Args::parse();

    let config = Figment::new().merge(Env::raw()).extract::<Config>()?;

    let github = github::Client::new(config.github_token.clone())?;
    let gitea = gitea::Client::new(
        "https://git.nregner.net/api/v1",
        config.gitea_token,
        config.github_token.clone(),
    )?;

    if matches!(args.command, None | Some(Commands::Sync)) {
        tracing::info!("Syncing repos...");
        sync::sync_repos(&github, &gitea).await?;
    }

    if matches!(args.command, None | Some(Commands::UpdateAccessToken)) {
        tracing::info!("Updating PAT...");
        access_token::update_access_token(
            "/var/lib/gitea/repositories".into(),
            &config.github_token,
        )?;
    }

    Ok(())
}
