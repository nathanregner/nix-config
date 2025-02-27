use color_eyre::eyre;
use generated::{types::ReposListForAuthenticatedUserType, Client};
use url::Url;

#[allow(dead_code)]
mod generated {
    include!(concat!(env!("OUT_DIR"), "/github.rs"));
}

pub struct GitHub {
    client: Client,
}

pub use generated::types::Repository;

impl GitHub {
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
                .repos_list_for_authenticated_user()
                .type_(ReposListForAuthenticatedUserType::Owner)
                .page(page)
                .per_page(100)
                .send()
                .await?
                .into_inner();
            page += 1;
            let done = response.len() < 100;
            repos.extend(response);
            if done {
                break;
            }
        }

        Ok(repos)
    }
}
