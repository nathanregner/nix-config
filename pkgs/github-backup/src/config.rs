use core::str;
use std::{
    fs::File,
    io::Write,
    path::{Path, PathBuf},
};

use color_eyre::eyre::Result;
use gix_config::Source;
use tempdir::TempDir;
use url::{Host, Url};

pub fn update_mirrors(repositories: PathBuf, pat: &str) -> Result<u32> {
    let mut count = 0;
    let mut stack = vec![repositories];
    while let Some(dir) = stack.pop() {
        let config = dir.to_path_buf().join("config");
        if config.is_file() {
            update_mirror(&config, pat)?;
            count += 1;
            continue;
        }
        for entry in std::fs::read_dir(dir)? {
            let path = entry?.path();
            if path.is_dir() {
                stack.push(path)
            }
        }
    }
    Ok(count)
}

#[tracing::instrument(err, skip(pat))]
fn update_mirror(config_path: &Path, pat: &str) -> Result<bool> {
    let mut config = gix_config::File::from_path_no_includes(config_path.into(), Source::Local)?;
    if update_mirror_pat(&mut config, &pat)? {
        let temp_dir = TempDir::new("git-config")?;
        let temp_config_path = temp_dir.path().join("config");
        let mut temp_file = File::create(&temp_config_path)?;
        config.write_to(&mut temp_file)?;
        temp_file.flush()?;
        std::fs::rename(temp_config_path, config_path)?;
        return Ok(true);
    }
    Ok(false)
}

fn update_mirror_pat(config: &mut gix_config::File, pat: &str) -> Result<bool> {
    let Ok(mut origin) = config.section_mut("remote", Some(b"origin".into())) else {
        return Ok(false);
    };
    let Some(url) = origin.value("url") else {
        return Ok(false);
    };

    let url = str::from_utf8(&url)?;
    let mut url = Url::parse(url)?;

    if let Some(Host::Domain("github.com")) = url.host()
        && url.path().starts_with("/nathanregner/")
        && let Some(password) = url.password()
        && password != pat
    {
        url.set_password(Some(pat)).expect("should have host");
        origin.set("url".try_into()?, url.to_string().as_bytes().into());
        return Ok(true);
    }

    return Ok(false);
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::process::Command;
    use tempdir::TempDir;

    #[test]
    fn update_public_mirror_noop() -> Result<()> {
        let url = "https://github.com/nathanregner/public.git";
        let (repo, config_path) = init(url)?;

        assert!(!update_mirror(&config_path, "github_pat_BBBBB")?);
        assert_eq!(
            get_remote(repo.path())?,
            format!("origin\t{url} (fetch)\norigin\t{url} (push)\n")
        );
        Ok(())
    }

    #[test]
    fn update_private_mirror_pat_unchanged() -> Result<()> {
        let url = "https://oauth2:github_pat_AAAAA@github.com/nathanregner/test.git";
        let (repo, config_path) = init(url)?;

        assert!(!update_mirror(&config_path, "github_pat_AAAAA")?);
        assert_eq!(
            get_remote(repo.path())?,
            format!("origin\t{url} (fetch)\norigin\t{url} (push)\n")
        );
        Ok(())
    }

    #[test]
    fn update_private_mirror_pat_changed() -> Result<()> {
        let url = "https://oauth2:github_pat_AAAAA@github.com/nathanregner/test.git";
        let (repo, config_path) = init(url)?;

        assert!(update_mirror(&config_path, "github_pat_BBBBB")?);
        let url = "https://oauth2:github_pat_BBBBB@github.com/nathanregner/test.git";
        assert_eq!(
            get_remote(repo.path())?,
            format!("origin\t{url} (fetch)\norigin\t{url} (push)\n")
        );
        Ok(())
    }

    #[test]
    fn update_mirrors_finds_repos() -> Result<()> {
        let repos = TempDir::new("mirror-test")?;

        let repo = repos.path().join("owner").join("example");
        std::fs::create_dir_all(&repo)?;
        Command::new("git")
            .current_dir(&repo)
            .arg("init")
            .arg("--bare")
            .output()?;
        Command::new("git")
            .current_dir(&repo)
            .args([
                "remote",
                "add",
                "origin",
                "https://oauth2:github_pat_AAAAA@github.com/nathanregner/test.git",
            ])
            .output()?;

        assert_eq!(update_mirrors(repos.path().into(), "github_pat_BBBBB")?, 1);
        let url = "https://oauth2:github_pat_BBBBB@github.com/nathanregner/test.git";
        assert_eq!(
            get_remote(&repo)?,
            format!("origin\t{url} (fetch)\norigin\t{url} (push)\n")
        );
        Ok(())
    }

    fn init(url: &str) -> Result<(TempDir, std::path::PathBuf), color_eyre::eyre::Error> {
        let repo = TempDir::new("mirror-test")?;
        Command::new("git")
            .current_dir(&repo)
            .arg("init")
            .output()?;
        Command::new("git")
            .current_dir(&repo)
            .args(["remote", "add", "origin", url])
            .output()?;
        let config_path = repo.path().join(".git").join("config");
        Ok((repo, config_path))
    }

    fn get_remote(dir: &Path) -> Result<String, color_eyre::eyre::Error> {
        let remote = Command::new("git")
            .current_dir(dir)
            .args(["remote", "-v"])
            .output()?
            .stdout;
        Ok(String::from_utf8_lossy(&remote).to_string())
    }
}
