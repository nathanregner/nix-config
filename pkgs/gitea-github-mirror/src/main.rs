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
    gitea_url: url::Url,
}

#[tokio::main]
async fn main() -> eyre::Result<()> {
    color_eyre::install()?;
    tracing_subscriber::fmt::init();

    let config = Figment::new().merge(Env::raw()).extract::<Config>()?;

    let github = github::Client::new(config.github_token.to_string())?;
    let gitea = gitea::Client::new(
        config.gitea_url,
        config.gitea_token,
        config.github_token.clone(),
    )?;

    tracing::info!("Syncing repos...");
    sync::sync_repos(&github, &gitea).await?;

    // https://github.com/go-gitea/gitea/issues/21192
    tracing::info!("Updating access token...");
    access_token::update_access_token("/var/lib/gitea/repositories".into(), &config.github_token)?;

    Ok(())
}
