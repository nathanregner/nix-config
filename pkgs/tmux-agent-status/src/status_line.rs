use crate::state::{AgentStatus, StatusFile};
use anyhow::Result;

pub fn output() -> Result<()> {
    let mut status_file = StatusFile::load()?;

    // prune
    status_file.remove_dead_agents();

    // compute stats
    let statuses = status_file.count_by_status();
    let working_count = *statuses.get(&AgentStatus::Working).unwrap_or(&0);
    let waiting_count = *statuses.get(&AgentStatus::Waiting).unwrap_or(&0);
    let idle_count = *statuses.get(&AgentStatus::Idle).unwrap_or(&0);

    let total = status_file.agents.len();
    if total == 0 {
        return Ok(());
    }

    if waiting_count > 0 {
        println!("#[fg=red,bold]* {waiting_count} waiting#[default]");
    } else {
        let mut parts = Vec::new();
        if working_count > 0 {
            parts.push(format!(
                "#[fg=gray,bold]! {} working#[default]",
                working_count
            ));
        }
        if idle_count > 0 {
            parts.push(format!("#[fg=green]* {} idle#[default]", idle_count));
        }
        println!("{}", parts.join(" "));
    }

    Ok(())
}
