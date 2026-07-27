use crate::{
    state::{AgentStatus, Liveness, StatusFile},
    tmux::{PaneId, TmuxPaneContext},
};
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
    PermissionPrompt(#[expect(dead_code)] ExtraFields),
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
    let ctx = match TmuxPaneContext::current() {
        Ok(ctx) => ctx,
        Err(err) => {
            tracing::warn!("Failed to load tmux pane context: {err}");
            return;
        }
    };

    // A sandboxed agent runs in its own PID namespace, so its PID is
    // meaningless to the host that reads the status file; it identifies itself
    // by container instead (set by the sandbox launcher). A native agent uses
    // its parent PID (Claude Code's PID) rather than the short-lived hook's.
    let liveness = match std::env::var("AMUX_CONTAINER") {
        Ok(id) if !id.is_empty() => Liveness::Container(id),
        _ => Liveness::Pid(std::os::unix::process::parent_id()),
    };

    let span = error_span!("hook", %ctx, ?liveness);
    let _span = span.enter();

    if let Err(err) = handle_inner(base_dirs, stdin, ctx.pane_id, liveness) {
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
    liveness: Liveness,
) -> Result<()> {
    let mut json = String::new();
    stdin
        .read_to_string(&mut json)
        .context("failed to read stdin")?;
    tracing::trace!("Parsing stdin: {json}");
    let event = serde_json::from_str::<HookInput>(&json)
        .with_context(|| format!("failed to parse input: {json}"))?;

    let status = match &event {
        HookInput::UserPromptSubmit(..)
        | HookInput::PreToolUse(..)
        | HookInput::PostToolUseFailure(..) => AgentStatus::Working,
        HookInput::PermissionPrompt(..) => AgentStatus::Waiting,
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

    let prev = status_file.set_agent(pane_id, liveness, status);
    status_file.save()?;
    tracing::debug!("Handled event {event:?}: {prev:?} -> {status:?}");

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
        let liveness = Liveness::Pid(std::process::id());
        handle_inner(base_dirs, json.as_bytes(), pane_id, liveness).unwrap();
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
    #[case(
        r#"{ "hook_event_name": "PermissionPrompt" }"#,
        Some(AgentStatus::Waiting)
    )]
    #[case(r#"{ "hook_event_name": "Stop" }"#, Some(AgentStatus::Idle))]
    fn hook_sets_status(#[case] json: &str, #[case] expected: Option<AgentStatus>) {
        let (_dir, base_dirs) = TestDirs::temp();

        run_hook(&base_dirs, json);

        assert_eq!(get_status(&base_dirs), expected, "{json}");
    }
}
