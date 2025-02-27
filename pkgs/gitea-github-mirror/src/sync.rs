use crate::{gitea, github};
use color_eyre::eyre;
use std::collections::HashMap;
use tokio::task::JoinSet;

pub async fn sync_repos(github: &github::Client, gitea: &gitea::Client) -> eyre::Result<()> {
    let (github_repos, mut gitea_repos) = load_repos(github, gitea).await?;

    let mut failed = 0;
    let mut join_set = JoinSet::new();
    for src in github_repos {
        while join_set.len() > 8 {
            if let Some(Ok(Err(err))) = join_set.join_next().await {
                tracing::error!(%err);
                failed += 1;
            }
        }
        if let Some(target) = gitea_repos.remove(&src.name) {
            join_set.spawn(sync_repo_settings(gitea.clone(), src, target))
        } else {
            join_set.spawn(migrate_repo(gitea.clone(), src))
        };
    }

    while let Some(result) = join_set.join_next().await {
        if let Ok(Err(err)) = result {
            tracing::error!(%err);
            failed += 1;
        }
    }

    if failed > 0 {
        eyre::bail!("Failed to migrate {failed} repositories");
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
            .map(|repo| (repo.name.clone(), repo))
            .collect(),
    ))
}

#[tracing::instrument(skip_all, fields(name = src.name))]
async fn migrate_repo(gitea: gitea::Client, src: github::Repository) -> eyre::Result<()> {
    tracing::info!("Repo does not exist, migrating...");
    gitea.migrate(&src).await?;
    tracing::info!("Done");
    Ok(())
}

#[tracing::instrument(skip_all, fields(name = src.name))]
async fn sync_repo_settings(
    gitea: gitea::Client,
    src: github::Repository,
    target: gitea::Repository,
) -> eyre::Result<()> {
    if target.mirror != Some(true) {
        eyre::bail!("{} exists but is not a mirror", target.name)
    }

    gitea.edit(src, target).await
}
