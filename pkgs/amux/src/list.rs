use crate::state::{Agent, PaneId, StatusFile};
use crate::theme::ansi_rgb;
use anyhow::{Context, Result, bail};
use std::collections::HashMap;
use std::io::Write;
use std::process::{Command, Stdio};
use std::time::SystemTime;
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

fn format_age(agent: &Agent) -> String {
    let Some(last_update) = agent.last_update else {
        return "-".to_string();
    };
    let Ok(elapsed) = SystemTime::now().duration_since(last_update) else {
        return "-".to_string();
    };
    let secs = elapsed.as_secs();
    if secs < 60 {
        format!("{secs}s")
    } else if secs < 3600 {
        format!("{}m", secs / 60)
    } else if secs < 86400 {
        format!("{}h", secs / 3600)
    } else {
        format!("{}d", secs / 86400)
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

    let mut fzf_entries: Vec<_> = panes
        .iter()
        .filter_map(|(id, pane)| {
            let agent = agents.get(id)?;
            Some((id, pane, agent))
        })
        .collect();

    fzf_entries.sort_by_key(|(_, _, agent)| (agent.status, agent.last_update));

    let fzf_lines: Vec<String> = fzf_entries
        .iter()
        .map(|(id, pane, agent)| {
            let icon = ansi_rgb(agent.status.color(), agent.status.icon());
            let age = format_age(agent);
            let attached = if pane.session_attached {
                "(attached)"
            } else {
                ""
            };

            // Format: <pane_id> <icon> <age> <description> <attached>
            format!(
                "{:<5} {} {:>4} {:<30} {}",
                id.as_str(),
                icon,
                age,
                pane.description,
                attached
            )
        })
        .collect();

    let mut fzf = Command::new("fzf")
        .args([
            "--ansi",
            "--no-sort",
            "--reverse",
            "--cycle",
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
