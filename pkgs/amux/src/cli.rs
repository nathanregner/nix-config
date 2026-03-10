use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "amux", version, about)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Handle Claude Code hooks
    Hook,
    /// Output status for tmux status bar
    StatusLine {
        /// Output all statuses with count=1 for testing
        #[arg(short, long)]
        test: bool,
    },
    /// List all agents with fzf for interactive selection
    List,
}
