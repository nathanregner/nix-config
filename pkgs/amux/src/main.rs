use crate::cli::*;
use clap::Parser;
use etcetera::BaseStrategy;
use std::fs::{self, File, OpenOptions};
use tracing_subscriber::EnvFilter;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;

mod cli;
mod hooks;
mod list;
mod state;
mod status_line;
mod theme;

fn main() {
    let base_dirs = etcetera::choose_base_strategy().expect("failed to determine base directories");
    init_logging(&base_dirs);

    let cli = Cli::parse();

    match cli.command {
        Commands::Hook => hooks::run(&base_dirs, std::io::stdin()),
        Commands::StatusLine { test } => {
            if let Err(err) = status_line::output(&base_dirs, test) {
                tracing::error!("{err:#}");
                std::process::exit(1);
            }
        }
        Commands::List => {
            if let Err(err) = list::output(&base_dirs) {
                tracing::error!("{err:#}");
                std::process::exit(1);
            }
        }
    }
}

fn init_logging(base_dirs: &dyn BaseStrategy) {
    let stderr_layer = tracing_subscriber::fmt::layer().with_writer(std::io::stderr);

    let (file_layer, log_err) = match create_log_file(base_dirs) {
        Ok(file) => (
            Some(
                tracing_subscriber::fmt::layer()
                    .with_writer(file)
                    .with_ansi(false),
            ),
            None,
        ),
        Err(err) => (None, Some(err)),
    };

    tracing_subscriber::registry()
        .with(EnvFilter::from_default_env())
        .with(stderr_layer)
        .with(file_layer)
        .init();

    if let Some(err) = log_err {
        tracing::error!("failed to create log file: {err}");
    }
}

fn create_log_file(base_dirs: &dyn BaseStrategy) -> Result<File, Box<dyn std::error::Error>> {
    let log_dir = base_dirs
        .state_dir()
        .unwrap_or_else(|| base_dirs.data_dir())
        .join("amux");
    fs::create_dir_all(&log_dir)?;

    let log_file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_dir.join("amux.log"))?;

    Ok(log_file)
}
