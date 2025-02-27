use crate::github;
use chrono::{Duration, Utc};
use clients::gitea::{
    self,
    types::{EditRepoOption, MigrateRepoOptions},
};
use color_eyre::eyre::{self, OptionExt};
use http::{header::AUTHORIZATION, HeaderValue};
use reqwest::header::HeaderMap;

pub use gitea::types::Repository;

#[derive(Clone)]
pub struct Client {
    client: gitea::Client,
    github_access_token: String,
}

impl Client {
    pub fn new(
        base_url: &str,
        access_token: String,
        github_access_token: String,
    ) -> eyre::Result<Self> {
        let mut headers = HeaderMap::default();
        headers.insert(AUTHORIZATION, {
            let mut bearer = HeaderValue::from_str(&format!("Bearer {access_token}"))?;
            bearer.set_sensitive(true);
            bearer
        });
        Ok(Self {
            client: gitea::Client::new_with_client(
                base_url,
                reqwest::Client::builder()
                    .default_headers(headers)
                    .build()?,
            ),
            github_access_token,
        })
    }

    pub async fn list_all(&self) -> eyre::Result<Vec<Repository>> {
        let mut page = 1;
        let mut repos = Vec::default();
        loop {
            let response = self
                .client
                .repo_search()
                .page(page)
                .limit(100)
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
                    .auth_token(Some(self.github_access_token.to_string()))
                    .mirror(true)
                    .private(true),
            )
            .send()
            .await?;
        Ok(())
    }

    pub async fn edit(&self, src: github::Repository, target: Repository) -> eyre::Result<()> {
        let mirror_interval = mirror_interval(&src);
        self.client
            .repo_edit()
            .owner(target.owner.login.ok_or_eyre("No repo owner?")?)
            .repo(target.name)
            .body(
                EditRepoOption::builder()
                    // .archived(Some(src.archived))
                    .mirror_interval(format!("{}h0m0s", mirror_interval.num_hours())),
            )
            .send()
            .await?;
        Ok(())
    }
}

fn mirror_interval(repo: &github::Repository) -> Duration {
    if repo.archived {
        return Duration::days(365);
    }

    if let Some(updated_at) = repo.updated_at {
        let days = (Utc::now() - updated_at).num_days();
        return Duration::days(match days {
            ..=30 => 1,
            31..=180 => 3,
            _ => 7,
        });
    }

    Duration::days(7)
}
