use crate::state::StatusFile;
use crate::tmux;
use anyhow::{Context, Result};
use etcetera::BaseStrategy;
use notify::{RecommendedWatcher, RecursiveMode, Watcher};
use std::path::Path;
use std::sync::mpsc;

/// Watch the status file for changes and refresh the tmux status bar.
///
/// The status file is written by hooks (including sandboxed agents that can't
/// reach the host tmux server), so a host-side watcher is what makes those
/// updates visible. We watch the containing directory rather than the file
/// itself: the file is truncated and rewritten in place, and watching the
/// directory also survives the file not existing yet.
pub fn run(base_dirs: &dyn BaseStrategy) -> Result<()> {
    let status_path = StatusFile::<()>::status_file_path(base_dirs);
    let watch_dir = status_path
        .parent()
        .context("status file has no parent directory")?
        .to_owned();
    std::fs::create_dir_all(&watch_dir)
        .with_context(|| format!("failed to create watch directory: {}", watch_dir.display()))?;

    let (tx, rx) = mpsc::channel();
    let mut watcher = RecommendedWatcher::new(
        // A send error just means the receiver is gone and we're shutting down.
        move |res| {
            let _ = tx.send(res);
        },
        notify::Config::default(),
    )
    .context("failed to create filesystem watcher")?;

    watcher
        .watch(&watch_dir, RecursiveMode::NonRecursive)
        .with_context(|| format!("failed to watch {}", watch_dir.display()))?;

    tracing::info!("watching {}", watch_dir.display());

    for event in rx {
        match event {
            Ok(event) if relevant(&event, &status_path) => {
                if let Err(err) = tmux::refresh_status_line() {
                    tracing::warn!("failed to refresh tmux status bar: {err:#}");
                }
            }
            Ok(_) => {}
            Err(err) => tracing::warn!("watch error: {err}"),
        }
    }

    Ok(())
}

/// Ignore events for unrelated files (e.g. the log file) that share the dir.
fn relevant(event: &notify::Event, status_path: &Path) -> bool {
    event.paths.iter().any(|p| p == status_path)
}
