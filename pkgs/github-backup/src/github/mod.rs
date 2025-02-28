use color_eyre::eyre;
use generated::{types::ReposListForAuthenticatedUserType, Client};
use http::{header::AUTHORIZATION, HeaderValue};
use reqwest::header::HeaderMap;
use url::Url;

#[allow(dead_code)]
mod generated {
    include!(concat!(env!("OUT_DIR"), "/github.rs"));
}

pub use generated::types::Repository;

pub struct GitHub {
    client: Client,
}

impl GitHub {
    pub fn new(base_url: Url, access_token: String) -> eyre::Result<Self> {
        let mut headers = HeaderMap::default();
        headers.insert(AUTHORIZATION, {
            let mut bearer = HeaderValue::from_str(&format!("Bearer {access_token}"))?;
            bearer.set_sensitive(true);
            bearer
        });
        Ok(Self {
            client: Client::new_with_client(
                "https://api.github.com/",
                reqwest::Client::builder()
                    .default_headers(headers)
                    .build()?,
            ),
        })
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
