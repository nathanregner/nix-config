use crate::cli::*;
use clap::Parser;
use tracing_subscriber::EnvFilter;

mod cli;
mod hooks;
mod list;
mod state;
mod status_line;
mod theme;

fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .with_writer(std::io::stderr)
        .init();

    let cli = Cli::parse();

    match cli.command {
        Commands::Hook => hooks::run(std::io::stdin()),
        Commands::StatusLine { test } => {
            if let Err(err) = status_line::output(test) {
                tracing::error!("{err:#}");
                std::process::exit(1);
            }
        }
        Commands::List => {
            if let Err(err) = list::output() {
                tracing::error!("{err:#}");
                std::process::exit(1);
            }
        }
    }
}
