use crate::state::{AgentStatus, PaneId, StatusFile};
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::io::Read;
use tmux_interface::{RefreshClient, Tmux};

/// https://code.claude.com/docs/en/hooks
#[derive(Deserialize, Debug)]
#[serde(tag = "hook_event_name")]
enum HookInput {
    UserPromptSubmit,
    PreToolUse,
    PostToolUse,
    Stop,
    Notification { notification_type: NotificationType },
}

/// https://code.claude.com/docs/en/hooks#notification
#[derive(Deserialize, Debug)]
#[serde(rename_all = "snake_case")]
enum NotificationType {
    IdlePrompt,
    PermissionPrompt,
    ElicitationDialog,
    #[serde(untagged)]
    Unknown(String),
}

#[derive(Serialize, Debug)]
struct HookOutput {
    #[serde(rename = "systemMessage")]
    system_message: String,
}

pub fn run(stdin: impl Read) {
    if let Err(err) = handle_inner(stdin) {
        tracing::error!("{err:#}");
        let output = HookOutput {
            system_message: format!("amux hook error: {err:#}"),
        };
        println!("{}", serde_json::to_string(&output).unwrap());
    }
}

fn handle_inner(mut stdin: impl Read) -> Result<()> {
    let pane_id = match get_current_tmux_pane() {
        Some(s) => s,
        None => return Ok(()), // Not in tmux
    };

    let mut json = String::new();
    stdin
        .read_to_string(&mut json)
        .context("failed to read stdin")?;
    let event = serde_json::from_str::<HookInput>(&json)
        .with_context(|| format!("failed to parse {json}"))?;

    let status = match event {
        HookInput::UserPromptSubmit | HookInput::PreToolUse | HookInput::PostToolUse => {
            Some(AgentStatus::Working)
        }
        HookInput::Stop => Some(AgentStatus::Idle),
        HookInput::Notification { notification_type } => match notification_type {
            NotificationType::IdlePrompt => Some(AgentStatus::Idle),
            NotificationType::PermissionPrompt | NotificationType::ElicitationDialog => {
                Some(AgentStatus::Waiting)
            }
            NotificationType::Unknown(ty) => {
                tracing::warn!("Ignoring unknown notification_type: {}", ty);
                None
            }
        },
    };

    if let Some(status) = status {
        let mut status_file = StatusFile::load_for_write()?;
        let should_notify = status == AgentStatus::Waiting;

        // Use parent PID (Claude Code's PID) rather than our own
        let pid = std::os::unix::process::parent_id();
        status_file.set_agent(pane_id, pid, status);
        status_file.save()?;

        // Refresh tmux status bar immediately
        if let Err(err) = Tmux::new()
            .command(RefreshClient::new().status_line())
            .output()
        {
            tracing::warn!("failed to refresh tmux status bar: {err:#}");
        }

        if should_notify {
            print!("\x07"); //  terminal bell
        }
    }

    Ok(())
}

fn get_current_tmux_pane() -> Option<PaneId> {
    match std::env::var("TMUX_PANE") {
        Ok(pane) => Some(PaneId::new(pane)),
        Err(_) => {
            tracing::warn!("TMUX_PANE not set - not running in tmux?");
            None
        }
    }
}
