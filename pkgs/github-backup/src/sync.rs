use crate::{gitea, github};
use color_eyre::eyre;
use std::collections::HashMap;

pub async fn sync_repos(github: &github::Client, gitea: &gitea::Client) -> eyre::Result<()> {
    let (github_repos, gitea_repos) = load_repos(github, gitea).await?;
    for src in github_repos {
        sync_repo(gitea, &gitea_repos, src).await?;
    }
    Ok(())
}

async fn load_repos(
    github: &github::Client,
    gitea: &gitea::Client,
) -> eyre::Result<(Vec<github::Repository>, HashMap<String, gitea::Repository>)> {
    let github = github.list_all();
    let gitea = gitea.list_all();

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
    gitea: &gitea::Client,
    targets: &HashMap<String, gitea::Repository>,
    src: github::Repository,
) -> Result<(), eyre::Error> {
    if let Some(target) = targets.get(&src.name) {
        if target.mirror != Some(true) {
            tracing::warn!("Repo exists but is not a mirror");
        }
    } else {
        tracing::info!("Repo does not exist, mirroring");
        gitea.migrate(&src).await?;
    }
    Ok(())
}
