use crate::state::{AgentStatus, PaneId, StatusFile};
use anyhow::{Context, Result};
use etcetera::BaseStrategy;
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, io::Read};
use tmux_interface::{RefreshClient, Tmux};
use tracing::error_span;

type ExtraFields = HashMap<String, serde_json::Value>;

/// https://code.claude.com/docs/en/hooks
#[derive(Deserialize, Debug)]
#[serde(tag = "hook_event_name")]
enum HookInput {
    UserPromptSubmit(#[expect(dead_code)] ExtraFields),
    PreToolUse(#[expect(dead_code)] ExtraFields),
    PostToolUse {
        tool_name: String,
        #[expect(dead_code)]
        #[serde(flatten)]
        extra_fields: ExtraFields,
    },
    PostToolUseFailure(#[expect(dead_code)] ExtraFields),
    Notification {
        notification_type: NotificationType,
        #[expect(dead_code)]
        #[serde(flatten)]
        extra_fields: ExtraFields,
    },
    Stop(#[expect(dead_code)] ExtraFields),
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
    let event = serde_json::from_str::<HookInput>(&json)
        .with_context(|| format!("failed to parse input: {json}"))?;

    let status = match &event {
        HookInput::UserPromptSubmit(..)
        | HookInput::PreToolUse(..)
        | HookInput::PostToolUseFailure(..) => AgentStatus::Working,
        HookInput::PostToolUse { tool_name, .. } => {
            if tool_name == "AskUserQuestion" {
                AgentStatus::Waiting
            } else {
                AgentStatus::Working
            }
        }
        HookInput::Notification {
            notification_type, ..
        } => match notification_type {
            NotificationType::IdlePrompt => AgentStatus::Idle,
            NotificationType::PermissionPrompt | NotificationType::ElicitationDialog => {
                AgentStatus::Waiting
            }
            NotificationType::Unknown(ty) => {
                tracing::warn!("Ignoring unknown notification_type: {}", ty);
                return Ok(());
            }
        },
        HookInput::Stop(..) => AgentStatus::Idle,
    };

    let mut status_file = StatusFile::load_for_write(base_dirs)?;
    let should_notify = status == AgentStatus::Waiting;

    status_file.set_agent(pane_id, parent_pid, status);
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

#[cfg(test)]
mod tests {
    use super::*;
    use amux_test::TestDirs;
    use rstest::rstest;

    fn run_hook(base_dirs: &dyn BaseStrategy, json: &str) {
        let pane_id = PaneId::new("%0");
        let parent_pid = std::process::id();
        handle_inner(base_dirs, json.as_bytes(), pane_id, parent_pid).unwrap();
    }

    fn get_status(base_dirs: &dyn BaseStrategy) -> Option<AgentStatus> {
        let status_file = StatusFile::load(base_dirs).unwrap();
        let pane_id = PaneId::new("%0");
        status_file.agents().get(&pane_id).map(|a| a.status)
    }

    #[rstest]
    #[case(
        r#"{ "hook_event_name": "UserPromptSubmit" }"#,
        Some(AgentStatus::Working)
    )]
    #[case( //
        r#"{ "hook_event_name": "PreToolUse" }"#,
        Some(AgentStatus::Working)
    )]
    #[case(
        r#"{ "hook_event_name": "PostToolUseFailure" }"#,
        Some(AgentStatus::Working)
    )]
    #[case(
        r#"{ "hook_event_name": "PostToolUse", "tool_name": "Bash" }"#,
        Some(AgentStatus::Working)
    )]
    #[case(
        r#"{ "hook_event_name": "PostToolUse", "tool_name": "AskUserQuestion" }"#,
        Some(AgentStatus::Waiting)
    )]
    #[case(
        r#"{ "hook_event_name": "Notification", "notification_type": "idle_prompt" }"#,
        Some(AgentStatus::Idle)
    )]
    #[case(
        r#"{ "hook_event_name": "Notification", "notification_type": "permission_prompt" }"#,
        Some(AgentStatus::Waiting)
    )]
    #[case(
        r#"{ "hook_event_name": "Notification", "notification_type": "elicitation_dialog" }"#,
        Some(AgentStatus::Waiting)
    )]
    #[case(
        r#"{ "hook_event_name": "Notification", "notification_type": "some_future_type" }"#,
        None
    )]
    #[case(r#"{ "hook_event_name": "Stop" }"#, Some(AgentStatus::Idle))]
    fn hook_sets_status(#[case] json: &str, #[case] expected: Option<AgentStatus>) {
        let (_dir, base_dirs) = TestDirs::temp();

        run_hook(&base_dirs, json);

        assert_eq!(get_status(&base_dirs), expected);
    }
}
