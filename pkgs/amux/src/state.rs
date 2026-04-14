use crate::theme;
use anyhow::{Context, Result};
use etcetera::BaseStrategy;
use nix::fcntl::{Flock, FlockArg};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet, HashMap};
use std::fs::{self, File, OpenOptions};
use std::io::{Read, Seek, Write};
use std::os::fd::{AsFd, OwnedFd};
use std::path::{Path, PathBuf};

#[derive(Serialize, Deserialize, Hash, PartialEq, Eq, PartialOrd, Ord, Clone, Debug)]
#[serde(transparent)]
pub struct PaneId(String);

impl PaneId {
    pub fn new(pane_id: impl Into<String>) -> Self {
        Self(pane_id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

#[derive(Serialize, Deserialize, Hash, Eq, PartialEq, PartialOrd, Ord, Copy, Clone, Debug)]
#[serde(rename_all = "snake_case")]
pub enum AgentStatus {
    /// Waiting for user permissions
    Waiting,
    /// Stopped
    Idle,
    /// Actively running
    Working,
}

impl AgentStatus {
    pub fn color(self) -> u32 {
        match self {
            Self::Waiting => theme::RED,
            Self::Idle => theme::FG,
            Self::Working => theme::BLACK_4,
        }
    }

    pub fn icon(self) -> &'static str {
        match self {
            Self::Waiting => "󰀦",
            Self::Idle => "󰒲",
            Self::Working => "",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    pub pid: u32,
    status: AgentStatus,
    #[serde(default, with = "humantime_serde")]
    last_update: Option<std::time::SystemTime>,
    #[serde(default, skip_serializing_if = "BTreeSet::is_empty")]
    waiting_agents: BTreeSet<String>,
}

impl Agent {
    fn new(pid: u32) -> Self {
        Self {
            pid,
            status: AgentStatus::Idle,
            last_update: None,
            waiting_agents: BTreeSet::new(),
        }
    }

    fn touch(&mut self) {
        self.last_update = Some(std::time::SystemTime::now());
    }

    pub fn status(&self) -> AgentStatus {
        if self.waiting_agents.is_empty() {
            self.status
        } else {
            AgentStatus::Waiting
        }
    }

    pub fn last_update(&self) -> Option<std::time::SystemTime> {
        self.last_update
    }

    pub fn is_waiting(&self) -> bool {
        !self.waiting_agents.is_empty()
    }

    pub fn set_status(&mut self, status: AgentStatus) {
        self.status = status;
        self.touch();
    }

    pub fn add_waiting(&mut self, agent_id: String) {
        self.waiting_agents.insert(agent_id);
        self.touch();
    }

    pub fn remove_waiting(&mut self, agent_id: &str) {
        self.waiting_agents.remove(agent_id);
        self.touch();
    }

    pub fn clear_waiting(&mut self) {
        self.waiting_agents.clear();
        self.touch();
    }
}

#[derive(Debug, Default, Serialize, Deserialize)]
struct StatusFileData {
    agents: BTreeMap<PaneId, Agent>,
}

/// Marker type for read-only mode (no lock held)
pub struct ReadMode;

/// Marker type for write mode (exclusive lock held)
pub struct WriteMode {
    flock: Flock<OwnedFd>,
}

/// Type-state status file with read/write separation.
///
/// - `StatusFile<ReadMode>` - no lock, allows inspection and dead agent detection
/// - `StatusFile<WriteMode>` - holds filesystem lock, allows mutation and save
pub struct StatusFile<'b, Mode> {
    data: StatusFileData,
    base_dirs: &'b dyn BaseStrategy,
    mode: Mode,
}

impl<T> StatusFile<'_, T> {
    fn status_file_path(base_dirs: &dyn BaseStrategy) -> PathBuf {
        base_dirs.cache_dir().join("amux/status.json")
    }
}

impl<'b> StatusFile<'b, ReadMode> {
    /// Load status file without acquiring a lock (read-only mode).
    pub fn load(base_dirs: &'b dyn BaseStrategy) -> Result<Self> {
        let path = Self::status_file_path(base_dirs);
        let data = match fs::read_to_string(path) {
            Ok(content) if content.is_empty() => StatusFileData::default(),
            Ok(content) => match serde_json::from_str(&content) {
                Ok(data) => data,
                Err(err) => {
                    tracing::warn!("corrupt status file: {err}");
                    StatusFileData::default()
                }
            },
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => StatusFileData::default(),
            Err(err) => {
                tracing::warn!("failed to read status file: {err}");
                StatusFileData::default()
            }
        };

        Ok(Self {
            data,
            base_dirs,
            mode: ReadMode,
        })
    }

    pub fn agents(&self) -> &BTreeMap<PaneId, Agent> {
        &self.data.agents
    }

    /// Count agents by their status.
    pub fn count_by_status(&self) -> HashMap<AgentStatus, u32> {
        self.data
            .agents
            .values()
            .fold(HashMap::new(), |mut acc, agent| {
                *acc.entry(agent.status()).or_default() += 1;
                acc
            })
    }

    /// Find agents whose processes are no longer alive.
    pub fn find_dead_agents(&self) -> Vec<PaneId> {
        self.data
            .agents
            .iter()
            .filter_map(|(key, entry)| match is_process_alive(entry.pid) {
                Ok(true) => None,
                Ok(false) => Some(key.clone()),
                Err(err) => {
                    tracing::error!("failed to signal process {}: {err:#}", entry.pid);
                    None
                }
            })
            .collect()
    }

    /// Upgrade to write mode by acquiring an exclusive lock.
    pub fn upgrade(&self) -> Result<StatusFile<'b, WriteMode>> {
        StatusFile::<WriteMode>::load_for_write(self.base_dirs)
    }
}

impl<'b> StatusFile<'b, WriteMode> {
    /// Load status file with an exclusive lock (write mode).
    pub fn load_for_write(base_dirs: &'b dyn BaseStrategy) -> Result<Self> {
        let path = Self::status_file_path(base_dirs);
        ensure_status_dir(&path)?;

        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .truncate(false)
            .open(&path)
            .with_context(|| format!("failed to open status file: {}", path.display()))?;
        let fd: OwnedFd = file.into();
        let flock = Flock::lock(fd, FlockArg::LockExclusive).map_err(|(_, err)| err)?;

        let mut content = String::new();
        File::from(flock.as_fd().try_clone_to_owned()?)
            .read_to_string(&mut content)
            .with_context(|| format!("failed to read status file: {}", path.display()))?;

        let data = if content.is_empty() {
            StatusFileData::default()
        } else {
            match serde_json::from_str(&content) {
                Ok(data) => data,
                Err(err) => {
                    tracing::warn!("corrupt status file, resetting: {err}");
                    StatusFileData::default()
                }
            }
        };

        Ok(Self {
            data,
            mode: WriteMode { flock },
            base_dirs,
        })
    }

    /// Get or create an agent for the given pane.
    pub fn get_or_create_agent(&mut self, pane_id: PaneId, pid: u32) -> &mut Agent {
        self.data
            .agents
            .entry(pane_id)
            .or_insert_with(|| Agent::new(pid))
    }

    /// Remove agents by their keys.
    pub fn remove_agents(&mut self, keys: &[PaneId]) {
        for key in keys {
            self.data.agents.remove(key);
        }
    }

    /// Save the status file and release the lock.
    pub fn save(self) -> Result<()> {
        let content =
            serde_json::to_string_pretty(&self.data).context("failed to serialize status")?;

        let mut file = File::from(self.mode.flock.as_fd().try_clone_to_owned()?);
        file.set_len(0).context("failed to truncate status file")?;
        file.rewind().context("failed to seek status file")?;
        file.write_all(content.as_bytes())
            .context("failed to write status file")?;

        Ok(())
    }
}

fn ensure_status_dir(path: &Path) -> Result<()> {
    if let Some(parent) = path.parent()
        && !parent.exists()
    {
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create status directory: {}", parent.display()))?;
    }
    Ok(())
}

fn is_process_alive(pid: u32) -> anyhow::Result<bool> {
    let pid = pid.try_into()?;
    let pid = nix::unistd::Pid::from_raw(pid);
    match nix::sys::signal::kill(pid, None) {
        Ok(_) => Ok(true),
        Err(nix::errno::Errno::ESRCH) => Ok(false),
        Err(err) => Err(err.into()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::Path;

    struct TestDirs(PathBuf);

    impl TestDirs {
        fn new(path: &Path) -> Self {
            Self(path.to_path_buf())
        }
    }

    impl BaseStrategy for TestDirs {
        fn home_dir(&self) -> &Path {
            &self.0
        }
        fn config_dir(&self) -> PathBuf {
            self.0.join("config")
        }
        fn data_dir(&self) -> PathBuf {
            self.0.join("data")
        }
        fn cache_dir(&self) -> PathBuf {
            self.0.join("cache")
        }
        fn state_dir(&self) -> Option<PathBuf> {
            Some(self.0.join("state"))
        }
        fn runtime_dir(&self) -> Option<PathBuf> {
            Some(self.0.join("runtime"))
        }
    }

    #[test]
    fn test_read_mode_handles_truncated_file() {
        let dir = tempfile::tempdir().unwrap();
        let base_dirs = TestDirs::new(dir.path());
        let path = StatusFile::<()>::status_file_path(&base_dirs);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(&path, r#"{"agents": {"#).unwrap();

        let status = StatusFile::load(&base_dirs).unwrap();
        assert!(status.data.agents.is_empty());
    }

    #[test]
    fn test_read_mode_handles_missing_file() {
        let dir = tempfile::tempdir().unwrap();
        let base_dirs = TestDirs::new(dir.path());

        let status = StatusFile::load(&base_dirs).unwrap();
        assert!(status.data.agents.is_empty());
    }

    #[test]
    fn test_write_mode_handles_truncated_file() {
        let dir = tempfile::tempdir().unwrap();
        let base_dirs = TestDirs::new(dir.path());
        let path = StatusFile::<()>::status_file_path(&base_dirs);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(&path, r#"{"agents": {"#).unwrap();

        let status = StatusFile::load_for_write(&base_dirs).unwrap();
        assert!(status.data.agents.is_empty());
    }
}
