use color_eyre::eyre;
use generated::{types::RepoSearchResultItem, Client};
use url::Url;

#[allow(dead_code)]
mod generated {
    include!(concat!(env!("OUT_DIR"), "/github.rs"));
}

pub struct GitHub {
    client: Client,
}

pub type Repo = RepoSearchResultItem;

impl GitHub {
    pub fn new(base_url: Url) -> Self {
        Self {
            client: Client::new(base_url.as_str()),
        }
    }

    pub async fn list_all(&self) -> eyre::Result<Vec<RepoSearchResultItem>> {
        let mut page = 0;
        let mut repos = Vec::default();
        loop {
            let response = self
                .client
                .search_repos()
                .q("user:nathanregner")
                .page(page)
                .per_page(100)
                .send()
                .await?
                .into_inner();
            page += 1;
            repos.extend(response.items);
            if !response.incomplete_results {
                break;
            }
        }

        Ok(repos)
    }
}
