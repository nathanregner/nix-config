use crate::state::{AgentStatus, PaneId, StatusFile};
use anyhow::{Context, Result};
use etcetera::BaseStrategy;
use serde::{Deserialize, Serialize};
use std::io::Read;
use tmux_interface::{RefreshClient, Tmux};
use tracing::error_span;

/// https://code.claude.com/docs/en/hooks
#[derive(Deserialize, Debug)]
struct HookPayload {
    #[serde(flatten)]
    event: HookEvent,
    agent_id: Option<String>,
}

const ROOT_AGENT_ID: &str = "__root__";

#[derive(Deserialize, Debug)]
#[serde(tag = "hook_event_name")]
enum HookEvent {
    UserPromptSubmit,
    PreToolUse,
    PostToolUse { tool_name: String },
    PostToolUseFailure,
    Notification { notification_type: NotificationType },
    Stop,
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

pub fn run(base_dirs: &dyn BaseStrategy, stdin: impl Read) {
    let pane_id = match std::env::var("TMUX_PANE") {
        Ok(id) => PaneId::new(id),
        Err(err) => {
            tracing::warn!("Failed to read TMUX_PANE: {err}, exiting");
            return;
        }
    };

    // Use parent PID (Claude Code's PID) rather than our own
    let parent_pid = std::os::unix::process::parent_id();

    let span = error_span!("hook", pane_id = pane_id.as_str(), parent_pid);
    let _span = span.enter();

    if let Err(err) = handle_inner(base_dirs, stdin, pane_id, parent_pid) {
        tracing::error!("{err:#}");
        let output = HookOutput {
            system_message: format!("amux hook error: {err:#}"),
        };
        println!("{}", serde_json::to_string(&output).unwrap());
    }
}

fn handle_inner(
    base_dirs: &dyn BaseStrategy,
    mut stdin: impl Read,
    pane_id: PaneId,
    parent_pid: u32,
) -> Result<()> {
    let mut json = String::new();
    stdin
        .read_to_string(&mut json)
        .context("failed to read stdin")?;
    let payload = serde_json::from_str::<HookPayload>(&json)
        .with_context(|| format!("failed to parse input: {json}"))?;

    let mut status_file = StatusFile::load_for_write(base_dirs)?;
    let agent = status_file.get_or_create_agent(pane_id, parent_pid);
    let agent_id = payload
        .agent_id
        .unwrap_or_else(|| ROOT_AGENT_ID.to_owned());

    match payload.event {
        HookEvent::PreToolUse | HookEvent::PostToolUseFailure => {
            if agent.is_waiting() {
                return Ok(());
            }
            agent.set_status(AgentStatus::Working);
        }
        HookEvent::UserPromptSubmit => {
            agent.remove_waiting(&agent_id);
            agent.set_status(AgentStatus::Working);
        }
        HookEvent::PostToolUse { tool_name } => {
            if tool_name == "AskUserQuestion" {
                agent.add_waiting(agent_id);
            } else {
                agent.remove_waiting(&agent_id);
                agent.set_status(AgentStatus::Working);
            }
        }
        HookEvent::Notification { notification_type } => match notification_type {
            NotificationType::IdlePrompt => {
                agent.clear_waiting();
                agent.set_status(AgentStatus::Idle);
            }
            NotificationType::PermissionPrompt | NotificationType::ElicitationDialog => {
                agent.add_waiting(agent_id);
            }
            NotificationType::Unknown(ty) => {
                tracing::warn!("Ignoring unknown notification_type: {}", ty);
                return Ok(());
            }
        },
        HookEvent::Stop => {
            agent.clear_waiting();
            agent.set_status(AgentStatus::Idle);
        }
    };

    let should_notify = agent.status() == AgentStatus::Waiting;
    status_file.save()?;

    // Refresh tmux status bar immediately
    if let Err(err) = Tmux::new()
        .command(RefreshClient::new().status_line())
        .output()
    {
        tracing::warn!("Failed to refresh tmux status bar: {err:#}");
    }

    if should_notify {
        print!("\x07"); //  terminal bell
    }

    Ok(())
}
