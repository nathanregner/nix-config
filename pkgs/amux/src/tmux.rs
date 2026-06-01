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
    pub session_name: String,
    pub window_name: String,
    pub pane_id: PaneId,
}

impl Display for TmuxPaneContext {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}/{}/{}",
            self.session_name,
            self.window_name,
            self.pane_id.as_str()
        )
    }
}

impl TmuxPaneContext {
    pub fn current() -> anyhow::Result<Self> {
        let pane_id = std::env::var("TMUX_PANE")
            .map(PaneId::new)
            .context("Failed to read TMUX_PANE")?;

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

        Ok(Self {
            session_name: session_name.to_owned(),
            window_name: window_name.to_owned(),
            pane_id,
        })
    }
}
