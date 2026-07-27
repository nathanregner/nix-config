use std::fmt::Display;

use anyhow::Context;
use serde::{Deserialize, Serialize};
use tmux_interface::{DisplayMessage, Tmux};

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

pub struct TmuxPaneContext {
    /// Session/window names, for logging only. A sandboxed hook can't reach the
    /// tmux server to resolve them, so they may be absent.
    pub session_name: Option<String>,
    pub window_name: Option<String>,
    pub pane_id: PaneId,
}

impl Display for TmuxPaneContext {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}/{}/{}",
            self.session_name.as_deref().unwrap_or("?"),
            self.window_name.as_deref().unwrap_or("?"),
            self.pane_id.as_str()
        )
    }
}

impl TmuxPaneContext {
    pub fn current() -> anyhow::Result<Self> {
        // The pane id is forwarded via $TMUX_PANE and is all the status write
        // needs. The session/window names require the tmux server, which a
        // sandboxed hook can't reach, so resolving them is best-effort.
        let pane_id = std::env::var("TMUX_PANE")
            .map(PaneId::new)
            .context("Failed to read TMUX_PANE")?;

        let (session_name, window_name) = match Self::resolve_names(&pane_id) {
            Ok((session, window)) => (Some(session), Some(window)),
            Err(err) => {
                tracing::debug!("Failed to resolve tmux session/window names: {err:#}");
                (None, None)
            }
        };

        Ok(Self {
            session_name,
            window_name,
            pane_id,
        })
    }

    fn resolve_names(pane_id: &PaneId) -> anyhow::Result<(String, String)> {
        let cmd = DisplayMessage::new()
            .target_pane(pane_id.as_str())
            .message("#{session_name}\n#{window_name}")
            .print();
        let output = Tmux::new().command(cmd).output()?;
        if !output.success() {
            anyhow::bail!("{}", String::from_utf8_lossy(&output.stderr()));
        }

        let stdout = output.stdout();
        let stdout = String::from_utf8_lossy(&stdout);
        let Ok([session_name, window_name]) =
            <[&str; 2]>::try_from(stdout.trim().split('\n').collect::<Vec<_>>())
        else {
            anyhow::bail!("Unparseable display-message output: {stdout}");
        };

        Ok((session_name.to_owned(), window_name.to_owned()))
    }
}
