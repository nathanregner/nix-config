use crate::state::{AgentStatus, StatusFile};
use anyhow::Result;
use std::collections::HashMap;
use std::fmt::Write;

pub fn output(test: bool) -> Result<()> {
    let statuses = if test {
        HashMap::from([
            (AgentStatus::Waiting, 1),
            (AgentStatus::Working, 1),
            (AgentStatus::Idle, 1),
        ])
    } else {
        let read_status = StatusFile::load()?;
        let dead_agents = read_status.find_dead_agents();
        let statuses = read_status.count_by_status();

        if !dead_agents.is_empty() {
            let mut write_status = read_status.upgrade()?;
            write_status.remove_agents(&dead_agents);
            write_status.save()?;
        }

        statuses
    };

    let waiting = *statuses.get(&AgentStatus::Waiting).unwrap_or(&0);
    let working = *statuses.get(&AgentStatus::Working).unwrap_or(&0);
    let idle = *statuses.get(&AgentStatus::Idle).unwrap_or(&0);

    if waiting + working + idle == 0 {
        return Ok(());
    }

    let thm_red = "#f38ba8";
    let thm_black4 = "#585b70";

    let mut f = String::with_capacity(256);

    if waiting > 0 {
        write!(f, "#[fg={thm_red},bold]󱚟 {waiting} waiting#[default]  ")?;
    }
    if working > 0 {
        write!(f, "#[fg={thm_black4},bold]󱜙 {working} working#[default]  ")?;
    }
    if idle > 0 {
        write!(f, "#[fg={thm_black4}]󱚡 {idle} idle#[default]  ")?;
    }

    println!("{}", f);

    Ok(())
}
