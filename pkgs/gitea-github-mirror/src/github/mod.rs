use std::str::FromStr;

use clients::github::{self, types::ReposListForAuthenticatedUserType};
use color_eyre::eyre;
use http::{header, HeaderName, HeaderValue};
use reqwest::header::HeaderMap;

pub use github::types::Repository;

pub struct Client {
    client: github::Client,
}

impl Client {
    pub fn new(access_token: String) -> eyre::Result<Self> {
        let mut headers = HeaderMap::default();
        headers.insert(header::AUTHORIZATION, {
            let mut bearer = HeaderValue::from_str(&format!("Bearer {access_token}"))?;
            bearer.set_sensitive(true);
            bearer
        });
        headers.insert(header::ACCEPT, HeaderValue::from_str("application/json")?);
        headers.insert(header::USER_AGENT, HeaderValue::from_str("nathanregner")?);
        headers.insert(
            HeaderName::from_str("X-GitHub-Api-Version")?,
            HeaderValue::from_str("2022-11-28")?,
        );
        Ok(Self {
            client: github::Client::new_with_client(
                "https://api.github.com",
                reqwest::Client::builder()
                    .default_headers(headers)
                    .build()?,
            ),
        })
    }

    pub async fn list_all(&self) -> eyre::Result<Vec<Repository>> {
        let mut page = 1;
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
