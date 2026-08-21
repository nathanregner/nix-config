use crate::theme;
use crate::tmux::PaneId;
use anyhow::{Context, Result};
use etcetera::BaseStrategy;
use nix::fcntl::{Flock, FlockArg};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, HashMap};
use std::fs::{self, File, OpenOptions};
use std::io::{Read, Seek, Write};
use std::os::fd::{AsFd, OwnedFd};
use std::path::{Path, PathBuf};
use std::process::Command;

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

pub type Pid = u32;

/// How to test whether an agent is still alive.
///
/// PIDs are namespaced, so a PID written by a sandboxed agent inside a
/// container is meaningless to the host process that reads the status file.
/// Sandboxed agents therefore record their container instead, which the host
/// checks via `container inspect`.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Liveness {
    /// Native agent: PID in the reader's process namespace.
    Pid(Pid),
    /// Sandboxed agent: Apple `container` name or id.
    Container(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    pub liveness: Liveness,
    pub status: AgentStatus,
    #[serde(default, with = "humantime_serde")]
    pub last_update: Option<std::time::SystemTime>,
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
    pub fn status_file_path(base_dirs: &dyn BaseStrategy) -> PathBuf {
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
                *acc.entry(agent.status).or_default() += 1;
                acc
            })
    }

    /// Find agents whose processes are no longer alive.
    pub fn find_dead_agents(&self) -> Vec<PaneId> {
        self.data
            .agents
            .iter()
            .filter_map(|(key, entry)| match is_agent_alive(&entry.liveness) {
                Ok(true) => None,
                Ok(false) => Some(key.clone()),
                Err(err) => {
                    tracing::error!("failed to check liveness of {:?}: {err:#}", entry.liveness);
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

    /// Set or update an agent's status.
    pub fn set_agent(
        &mut self,
        pane_id: PaneId,
        liveness: Liveness,
        status: AgentStatus,
    ) -> Option<AgentStatus> {
        let prev = self.data.agents.insert(
            pane_id,
            Agent {
                liveness,
                status,
                last_update: Some(std::time::SystemTime::now()),
            },
        );
        Some(prev?.status)
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

fn is_agent_alive(liveness: &Liveness) -> anyhow::Result<bool> {
    match liveness {
        Liveness::Pid(pid) => is_process_alive(*pid),
        Liveness::Container(id) => is_container_alive(id),
    }
}

fn is_process_alive(pid: Pid) -> anyhow::Result<bool> {
    let pid = pid.try_into()?;
    let pid = nix::unistd::Pid::from_raw(pid);
    match nix::sys::signal::kill(pid, None) {
        Ok(_) => Ok(true),
        Err(nix::errno::Errno::ESRCH) => Ok(false),
        Err(err) => Err(err.into()),
    }
}

/// A sandboxed agent is alive iff its Apple `container` is still running.
/// `container inspect` exits non-zero when the container no longer exists.
/// Unlike docker it has no `-f` template flag, so it emits a JSON array whose
/// element's `.status.state` is `running` while the container lives.
fn is_container_alive(id: &str) -> anyhow::Result<bool> {
    let output = Command::new("container")
        .args(["inspect", id])
        .output()
        .context("failed to run container inspect")?;

    if !output.status.success() {
        return Ok(false);
    }

    #[derive(Deserialize)]
    struct Inspect {
        status: InspectStatus,
    }

    #[derive(Deserialize)]
    struct InspectStatus {
        state: String,
    }

    let containers: Vec<Inspect> = serde_json::from_slice(&output.stdout)
        .context("failed to parse container inspect output")?;

    Ok(containers
        .first()
        .is_some_and(|c| c.status.state == "running"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use amux_test::TestDirs;

    #[test]
    fn test_read_mode_handles_truncated_file() {
        let (dir, base_dirs) = TestDirs::temp();
        let path = StatusFile::<()>::status_file_path(&base_dirs);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(&path, r#"{"agents": {"#).unwrap();

        let status = StatusFile::load(&base_dirs).unwrap();
        assert!(status.data.agents.is_empty());
        drop(dir);
    }

    #[test]
    fn test_read_mode_handles_missing_file() {
        let (_dir, base_dirs) = TestDirs::temp();

        let status = StatusFile::load(&base_dirs).unwrap();
        assert!(status.data.agents.is_empty());
    }

    #[test]
    fn test_write_mode_handles_truncated_file() {
        let (dir, base_dirs) = TestDirs::temp();
        let path = StatusFile::<()>::status_file_path(&base_dirs);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(&path, r#"{"agents": {"#).unwrap();

        let status = StatusFile::load_for_write(&base_dirs).unwrap();
        assert!(status.data.agents.is_empty());
        drop(dir);
    }
}
