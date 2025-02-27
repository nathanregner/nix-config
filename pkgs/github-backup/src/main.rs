#![feature(let_chains)]

use std::collections::HashMap;

use color_eyre::eyre;
use gitea::Gitea;
use github::GitHub;

mod config;
mod gitea;
mod github;

async fn load_repos(
    github_client: &GitHub,
    gitea_client: &Gitea,
) -> eyre::Result<(
    HashMap<String, github::Repository>,
    HashMap<String, gitea::Repository>,
)> {
    let github = github_client.list_all();
    let gitea = gitea_client.list_all();

    let (github, gitea) = tokio::join!(github, gitea);
    Ok((
        github?
            .into_iter()
            .map(|repo| (repo.name.clone(), repo))
            .collect(),
        gitea?
            .into_iter()
            .filter_map(|repo| Some((repo.name?.clone(), repo)))
            .collect(),
    ))
}

fn main() -> eyre::Result<()> {
    color_eyre::install()?;
    tracing_subscriber::fmt::init();
    // config::update_mirrors("/tmp".into(), "bogus")?;
    tracing::info!("test");
    Ok(())
}
