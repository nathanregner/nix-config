use anyhow::{Context, Result};
use etcetera::BaseStrategy;
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashMap};
use std::fs;
use std::path::PathBuf;

#[derive(Serialize, Deserialize, Hash, Eq, PartialEq, Copy, Clone, Debug)]
#[serde(rename_all = "snake_case")]
pub enum AgentStatus {
    /// Actively running
    Working,
    /// Waiting for user permissions
    Waiting,
    /// Stopped
    Idle,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentEntry {
    pub session: String,
    pub pid: u32,
    pub status: AgentStatus,
}

#[derive(Debug, Default, Serialize, Deserialize)]
pub struct StatusFile {
    pub agents: BTreeMap<String, AgentEntry>,
    // TODO: last checked time
}

impl StatusFile {
    pub fn load() -> Result<Self> {
        let base_dirs =
            etcetera::choose_base_strategy().context("failed to determine base directories")?;
        Self::load_with(&base_dirs)
    }

    pub fn load_with(base_dirs: &dyn BaseStrategy) -> Result<Self> {
        let path = status_file_path(base_dirs)?;
        if path.exists() {
            let content = fs::read_to_string(&path)
                .with_context(|| format!("failed to read status file: {}", path.display()))?;
            serde_json::from_str(&content)
                .with_context(|| format!("failed to parse status file: {}", path.display()))
        } else {
            Ok(Self::default())
        }
    }

    pub fn save(&self) -> Result<()> {
        let base_dirs =
            etcetera::choose_base_strategy().context("failed to determine base directories")?;
        self.save_with(&base_dirs)
    }

    pub fn save_with(&self, base_dirs: &dyn BaseStrategy) -> Result<()> {
        let path = status_file_path(base_dirs)?;
        let content = serde_json::to_string_pretty(self).context("failed to serialize status")?;
        fs::write(&path, content)
            .with_context(|| format!("failed to write status file: {}", path.display()))
    }

    pub fn set_agent(&mut self, session: &str, pid: u32, status: AgentStatus) {
        let key = format!("{}.{}", session, pid);
        self.agents.insert(
            key,
            AgentEntry {
                session: session.to_string(),
                pid,
                status,
            },
        );
    }

    pub fn remove_dead_agents(&mut self) {
        self.agents
            .retain(|_, entry| match is_process_alive(entry.pid) {
                Ok(alive) => alive,
                Err(err) => {
                    tracing::error!("failed to signal process {}: {err:#}", entry.pid);
                    true
                }
            });
    }

    pub fn count_by_status(&self) -> HashMap<AgentStatus, u32> {
        self.agents.values().fold(HashMap::new(), |mut acc, agent| {
            *acc.entry(agent.status).or_default() += 1;
            acc
        })
    }
}

fn status_file_path(base_dirs: &dyn BaseStrategy) -> Result<PathBuf> {
    let status_dir = base_dirs.cache_dir().join("tmux-agent-status");
    fs::create_dir_all(&status_dir).with_context(|| {
        format!(
            "failed to create status directory: {}",
            status_dir.display()
        )
    })?;
    Ok(status_dir.join("status.json"))
}

fn is_process_alive(pid: u32) -> anyhow::Result<bool> {
    let pid = pid.try_into()?;
    let pid = nix::unistd::Pid::from_raw(pid);
    match nix::sys::signal::kill(pid, None) {
        Ok(_) => Ok(true),
        Err(nix::errno::Errno::ESRCH) => Ok(false), // No such process
        Err(err) => Err(err.into()),
    }
}
