use serde::Deserialize;
use std::path::{Path, PathBuf};

use crate::{cli::Args, Profile, Result};

pub fn get_latest_build(
    Args {
        instance,
        project,
        jobset,
        profile,
        job,
        ..
    }: &Args,
) -> Result<Build> {
    let job = match job {
        Some(job) => job.to_string(),
        None => {
            let hostname = whoami::fallible::hostname()?;
            let profile = match profile {
                Profile::Home => "home",
                Profile::System => "system",
            };
            format!("deploy.{hostname}.{profile}")
        }
    };

    let url = format!("{instance}/job/{project}/{jobset}/{job}/latest");
    let response: Build = ureq::get(&url)
        .set("Accept", "application/json")
        .call()?
        .into_json()?;
    Ok(response)
}

#[derive(Deserialize, Debug)]
pub struct Build {
    #[serde(rename = "buildoutputs")]
    build_outputs: BuildOutput,
}

impl Build {
    pub fn out_path(&self) -> &Path {
        &self.build_outputs.out.path
    }
}

#[derive(Deserialize, Debug)]
struct BuildOutput {
    out: OutPath,
}

#[derive(Deserialize, Debug)]
struct OutPath {
    path: PathBuf,
}
