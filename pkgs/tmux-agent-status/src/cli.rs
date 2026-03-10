use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "tmux-agent-status")]
#[command(version, about = "Monitor Claude Code agents in tmux")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Handle Claude Code hooks
    Hook,
    /// Output status for tmux status bar
    StatusLine,
}
