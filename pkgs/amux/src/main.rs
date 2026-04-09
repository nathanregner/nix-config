use crate::cli::*;
use clap::Parser;
use std::fs::{self, File, OpenOptions};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

mod cli;
mod hooks;
mod list;
mod state;
mod status_line;
mod theme;

fn main() {
    init_logging();

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

fn init_logging() {
    let stderr_layer = tracing_subscriber::fmt::layer().with_writer(std::io::stderr);

    let (file_layer, log_err) = match create_log_file() {
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

fn create_log_file() -> Result<File, Box<dyn std::error::Error>> {
    let state_dir = state::state_dir()?;
    let log_dir = state_dir.join("amux/logs");
    fs::create_dir_all(&log_dir)?;

    let session = std::env::var("TMUX").ok().and_then(|tmux| {
        tmux.split(',').next().and_then(|socket_path| {
            std::path::Path::new(socket_path)
                .file_name()
                .and_then(|n| n.to_str())
                .map(|s| s.to_string())
        })
    });
    let pane = std::env::var("TMUX_PANE").ok();
    let pid = std::process::id();

    let filename = match (session, pane) {
        (Some(session), Some(pane)) => format!("{session}_{pane}_{pid}.log"),
        (Some(session), None) => format!("{session}_{pid}.log"),
        (None, Some(pane)) => format!("{pane}_{pid}.log"),
        (None, None) => format!("{pid}.log"),
    };

    let log_file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_dir.join(filename))?;

    Ok(log_file)
}
