use crate::state::{AgentStatus, PaneId, StatusFile};
use anyhow::{Context, Result, bail};
use std::collections::HashMap;
use std::io::Write;
use std::process::{Command, Stdio};
use tmux_interface::{ListPanes, SwitchClient, Tmux};

struct PaneInfo {
    description: String,
    session_attached: bool,
}

fn list_panes() -> Result<HashMap<PaneId, PaneInfo>> {
    let cmd = ListPanes::new()
        .all()
        .format("#{pane_id}:#{session_name}/#{window_name}:#{session_attached}");
    let output = Tmux::new()
        .command(cmd)
        .output()
        .context("failed to list tmux sessions")?;

    if !output.success() {
        bail!("tmux list-sessions failed");
    }

    let stdout_bytes = output.stdout();
    let stdout = String::from_utf8_lossy(&stdout_bytes);
    let mut info = HashMap::new();

    for line in stdout.lines() {
        let parts: Vec<&str> = line.split(':').collect();
        if parts.len() >= 2 {
            let id = PaneId::new(parts[0]);
            let description = parts[1].to_string();
            let session_attached = parts[2] == "1";
            info.insert(
                id,
                PaneInfo {
                    description,
                    session_attached,
                },
            );
        }
    }

    Ok(info)
}

fn switch_to_pane(id: &PaneId) -> Result<()> {
    let cmd = SwitchClient::new().target_session(id.as_str());
    Tmux::new()
        .command(cmd)
        .output()
        .context("failed to switch to pane")?;
    Ok(())
}

fn status_icon(status: AgentStatus) -> &'static str {
    match status {
        AgentStatus::Waiting => "\x1b[31m󱚟\x1b[0m", // red
        AgentStatus::Working => "\x1b[33m󱜙\x1b[0m", // yellow
        AgentStatus::Idle => "\x1b[32m󱚡\x1b[0m",    // green
    }
}

pub fn output() -> Result<()> {
    let status = StatusFile::load()?;
    let dead_agents = status.find_dead_agents();

    let agents = status.agents();

    if !dead_agents.is_empty() {
        let mut status = status.upgrade()?;
        status.remove_agents(&dead_agents);
        status.save()?;
    }

    let panes = list_panes().context("failed to list tmux painspanes")?;

    if panes.is_empty() {
        println!("No panes");
        return Ok(());
    }

    let fzf_lines: Vec<String> = panes
        .iter()
        .filter_map(|(id, pane)| {
            let agent = agents.get(id)?;
            let status = agent.status;
            let icon = status_icon(status);
            let attached = if pane.session_attached {
                "(attached)"
            } else {
                ""
            };

            // Format: <pane_id> <icon> <description> <attached>
            Some(format!(
                "{} {} {:<30} {}",
                id.as_str(),
                icon,
                pane.description,
                attached
            ))
        })
        .collect();

    let mut fzf = Command::new("fzf")
        .args([
            "--ansi",
            "--no-sort",
            "--reverse",
            "--preview=tmux capture-pane -e -p -t {1} 2>/dev/null || echo 'No preview'",
            "--preview-window=right:50%:nowrap",
            "--bind=j:down,k:up",
            // Border styling
            "--input-border",
            "--input-label= Panes ",
            "--info=inline-right",
            "--list-border",
            "--preview-border",
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .context("failed to spawn fzf - is it installed?")?;

    if let Some(mut stdin) = fzf.stdin.take() {
        for line in &fzf_lines {
            writeln!(stdin, "{}", line)?;
        }
    }

    let output = fzf.wait_with_output().context("fzf failed")?;

    if !output.status.success() {
        return Ok(());
    }

    let selection = String::from_utf8_lossy(&output.stdout);
    let selection = selection.trim();

    if selection.is_empty() {
        return Ok(());
    }

    // Pane ID is the first field
    let pane_id = selection.split_whitespace().next().unwrap_or("");

    if pane_id.is_empty() {
        return Ok(());
    }

    switch_to_pane(&PaneId::new(pane_id))?;
    Ok(())
}
