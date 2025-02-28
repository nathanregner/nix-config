use std::collections::HashMap;

use color_eyre::eyre;

use crate::{
    gitea::{self, Gitea},
    github::{self, GitHub},
};

pub async fn sync_repos(github_client: &GitHub, gitea_client: &Gitea) -> eyre::Result<()> {
    let (github_repos, gitea_repos) = load_repos(github_client, gitea_client).await?;
    for src in github_repos {
        sync_repo(gitea_client, &gitea_repos, src).await?;
    }
    Ok(())
}

async fn load_repos(
    github_client: &GitHub,
    gitea_client: &Gitea,
) -> eyre::Result<(Vec<github::Repository>, HashMap<String, gitea::Repository>)> {
    let github = github_client.list_all();
    let gitea = gitea_client.list_all();

    let (github, gitea) = tokio::join!(github, gitea);
    Ok((
        github?,
        gitea?
            .into_iter()
            .filter_map(|repo| Some((repo.name.clone()?, repo)))
            .collect(),
    ))
}

#[tracing::instrument(skip_all,fields(name = src.name))]
async fn sync_repo(
    gitea_client: &Gitea,
    gitea_repos: &HashMap<String, gitea::Repository>,
    src: github::Repository,
) -> Result<(), eyre::Error> {
    if let Some(target) = gitea_repos.get(&src.name) {
        if target.mirror != Some(true) {
            tracing::warn!("Repo exists but is not a mirror");
        }
    } else {
        tracing::info!("Repo does not exist, mirroring");
        gitea_client.migrate(&src).await?;
    }
    Ok(())
}
