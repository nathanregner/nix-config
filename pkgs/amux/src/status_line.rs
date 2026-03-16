use crate::state::{AgentStatus, StatusFile};
use crate::theme::hex_rgb;
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

    if statuses.is_empty() {
        return Ok(());
    }

    let mut status_line = String::with_capacity(256);

    let mut push = |status: AgentStatus| {
        let count = *statuses.get(&status).unwrap_or(&0);
        if count == 0 {
            return Ok(());
        }
        write!(
            status_line,
            "#[fg={},bold]{} {}#[default]  ",
            hex_rgb(status.color()),
            status.icon(),
            count
        )
    };

    push(AgentStatus::Waiting)?;
    push(AgentStatus::Idle)?;
    push(AgentStatus::Working)?;
    println!("{}", status_line);

    Ok(())
}
