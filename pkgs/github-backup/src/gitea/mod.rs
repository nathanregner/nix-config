use color_eyre::eyre;
use generated::{
    types::{MigrateRepoOptions, MigrateRepoOptionsService, Repository},
    Client,
};
use url::Url;

#[allow(dead_code)]
mod generated {
    include!(concat!(env!("OUT_DIR"), "/gitea.rs"));
}

pub struct Gitea {
    client: Client,
}

impl Gitea {
    pub fn new(base_url: Url) -> Self {
        Self {
            client: Client::new(base_url.as_str()),
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
            if response.len() == 0 {
                break;
            }
            page += 1;
            repos.extend(response);
        }

        Ok(repos)
    }

    pub async fn migrate(&self) -> eyre::Result<()> {
        self.client
            .repo_migrate()
            .body(MigrateRepoOptions {
                auth_password: todo!(),
                auth_token: todo!(),
                auth_username: todo!(),
                clone_addr: todo!(),
                description: todo!(),
                issues: Some(false),
                labels: Some(false),
                lfs: Some(true),
                lfs_endpoint: None,
                milestones: Some(false),
                mirror: Some(true),
                mirror_interval: None,
                private: Some(true),
                pull_requests: Some(false),
                releases: Some(false),
                repo_name: todo!(),
                repo_owner: todo!(),
                service: Some(MigrateRepoOptionsService::Github),
                uid: None,
                wiki: Some(false),
            })
            .send()
            .await?;
        Ok(())
    }
}
