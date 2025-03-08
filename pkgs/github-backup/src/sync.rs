use crate::{gitea, github};
use color_eyre::eyre;
use std::collections::HashMap;
use tokio::task::JoinSet;

pub async fn sync_repos(github: &github::Client, gitea: &gitea::Client) -> eyre::Result<()> {
    let (github_repos, gitea_repos) = load_repos(github, gitea).await?;
    let mut failed = 0;
    let mut join_set = JoinSet::new();
    for src in github_repos {
        while join_set.len() > 8 {
            if let Some(Err(_)) = join_set.join_next().await {
                failed += 1;
            }
        }

        if let Some(target) = gitea_repos.get(&src.name) {
            if target.mirror != Some(true) {
                tracing::warn!("{} exists but is not a mirror", target.name);
            }
        } else {
            join_set.spawn(sync_repo(gitea.clone(), src));
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

#[tracing::instrument(skip_all,fields(name = src.name))]
async fn sync_repo(gitea: gitea::Client, src: github::Repository) -> Result<(), ()> {
    tracing::info!("Repo does not exist, mirroring...");
    if let Err(err) = gitea.migrate(&src).await {
        tracing::error!(%err);
        return Err(());
    } else {
        tracing::info!("Done");
    }
    Ok(())
}
