use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::{
    collections::HashMap,
    ffi::OsStr,
    path::{Path, PathBuf},
    process::Command,
    time::SystemTime,
};

#[derive(Clone, Debug, PartialEq)]
pub struct GcRoot {
    pub symlink: PathBuf,
    pub modified: SystemTime,
    pub store_path: PathBuf,
}

pub fn gc_roots() -> Result<Vec<GcRoot>> {
    let output = Command::new("nix-store")
        .args(["--gc", "--print-roots"])
        .output()?;

    let mut roots = Vec::new();
    for line in String::from_utf8_lossy(&output.stdout).lines() {
        // skip /proc, {memory}, {censored}, {lsof}, {temp:...}
        if line.starts_with("\"{") {
            continue;
        }

        // "<symlink>" -> <store-path>
        let Some((symlink, store_path)) = line.split_once(" -> ") else {
            continue;
        };
        let symlink = PathBuf::from(symlink.trim_matches('"'));

        // skip /proc, {memory}, {censored}, {lsof}, {temp:...}
        if symlink.starts_with("/proc/") || symlink.starts_with("{") {
            continue;
        }

        let modified = std::fs::symlink_metadata(&symlink)
            .and_then(|m| m.modified())
            .unwrap_or(SystemTime::UNIX_EPOCH);

        roots.push(GcRoot {
            symlink,
            modified,
            store_path: PathBuf::from(store_path),
        });
    }

    Ok(roots)
}

pub type PathInfoMap = HashMap<PathBuf, PathInfo>;

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct PathInfo {
    pub nar_size: u64,
    pub references: Vec<PathBuf>,
}

pub fn path_info(
    derivation: bool,
    installables: impl IntoIterator<Item = impl AsRef<OsStr>>,
) -> Result<PathInfoMap> {
    let mut cmd = Command::new("nix");
    cmd.args(["path-info", "-r", "--json", "--json-format", "1"]);
    if derivation {
        cmd.arg("--derivation");
    }
    cmd.args(installables);
    let output = cmd.output()?;

    Ok(serde_json::from_slice(&output.stdout)?)
}
