use color_eyre::eyre;
use generated::{types::MigrateRepoOptions, Client};
use url::Url;

use crate::github;

pub use generated::types::Repository;

#[allow(dead_code)]
mod generated {
    include!(concat!(env!("OUT_DIR"), "/gitea.rs"));
}

pub struct Gitea {
    client: Client,
    github_pat: String,
}

impl Gitea {
    pub fn new(base_url: Url, github_pat: String) -> Self {
        Self {
            client: Client::new(base_url.as_str()),
            github_pat,
        }
    }

    pub async fn list_all(&self) -> eyre::Result<Vec<Repository>> {
        let mut page = 0;
        let mut repos = Vec::default();
        loop {
            let response = self
                .client
                .repo_search()
                .page(page)
                .send()
                .await?
                .into_inner()
                .data;
            if response.is_empty() {
                break;
            }
            page += 1;
            repos.extend(response);
        }

        Ok(repos)
    }

    pub async fn migrate(&self, repo: &github::Repository) -> eyre::Result<()> {
        self.client
            .repo_migrate()
            .body(
                MigrateRepoOptions::builder()
                    .repo_name(&repo.name)
                    .clone_addr(&repo.clone_url)
                    .auth_token(Some(self.github_pat.to_string()))
                    .mirror(true)
                    .private(true),
            )
            .send()
            .await?;
        Ok(())
    }
}
