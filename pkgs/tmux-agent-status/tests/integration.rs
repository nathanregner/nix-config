use assert_cmd::cargo::*;
use predicates::prelude::*;
use std::{
    sync::atomic::{AtomicU32, Ordering},
    time::Duration,
};
use tempfile::TempDir;
use tmux_interface::{CapturePane, NewSession, SendKeys, StdIO, Tmux};

struct TestEnv {
    _cache_dir: TempDir,
    _socket_dir: TempDir,
    _server: std::process::Child,
    cache_dir: String,
    socket_path: String,
    session_name: String,
    marker_counter: AtomicU32,
}

impl TestEnv {
    fn new(test_name: &str) -> Self {
        let cache_temp = TempDir::new().unwrap();
        let cache_dir = cache_temp.path().to_string_lossy().to_string();

        let socket_temp = TempDir::new().unwrap();
        let socket_path = socket_temp.path().join("tmux.sock");
        let socket_path = socket_path.to_string_lossy().to_string();

        let session_name = format!(
            "tmux-agent-status-test-{}-{}",
            test_name,
            std::process::id()
        );

        // Start tmux server in foreground mode (no daemon) so we can kill it on drop
        // Note: -D flag cannot be combined with a command, so we start the server first
        let server = Tmux::new()
            .file("/dev/null")
            .socket_path(&socket_path)
            .no_daemon()
            .stdin(Some(StdIO::Null))
            .stdout(Some(StdIO::Null))
            .stderr(Some(StdIO::Null))
            .spawn()
            .expect("failed to start tmux server");

        // Wait for server to be ready by retrying session creation
        retry(100, || {
            Tmux::new()
                .file("/dev/null")
                .socket_path(&socket_path)
                .command(
                    NewSession::new()
                        .detached()
                        .session_name(&session_name)
                        .shell_command("bash --norc --noprofile"),
                )
                .output()
        })
        .expect("failed to create tmux session");

        let env = Self {
            _cache_dir: cache_temp,
            _socket_dir: socket_temp,
            _server: server,
            cache_dir,
            socket_path,
            session_name,
            marker_counter: AtomicU32::new(0),
        };

        // Wait for shell to be ready
        env.run_and_wait(":");

        env
    }

    fn tmux(&self) -> Tmux<'_> {
        Tmux::new().file("/dev/null").socket_path(&self.socket_path)
    }

    pub fn status_line(&self) -> assert_cmd::assert::Assert {
        let mut cmd = cargo_bin_cmd!();
        cmd.env("XDG_CACHE_HOME", &self.cache_dir)
            .args(["status-line"]);
        cmd.assert()
            .append_context("pane content", self.capture_pane())
            .success()
    }

    /// Run hook command inside the tmux session's shell.
    /// The shell stays alive, so its PID (the parent of the hook) remains valid.
    pub fn run_hook(&self, stdin: &str) {
        let bin_path = cargo_bin!("tmux-agent-status");
        let cmd = format!(
            "echo '{}' | XDG_CACHE_HOME={} {} hook",
            stdin.replace('\'', "'\\''"),
            self.cache_dir,
            bin_path.display(),
        );
        self.run_and_wait(&cmd);
    }

    /// Run a command and wait for it to complete using a marker
    fn run_and_wait(&self, cmd: &str) {
        let id = self.marker_counter.fetch_add(1, Ordering::Relaxed);
        // Use printf to add a prefix that won't appear in the command line itself
        self.send_keys(&format!("{cmd} && printf 'DONE:%s\\n' {id}"));
        self.wait_for_marker(&format!("DONE:{id}"));
    }

    fn send_keys(&self, keys: &str) {
        // Build send-keys command manually since tmux_interface's SendKeys
        // only supports a single key parameter
        let mut cmd = SendKeys::new().target_pane(&self.session_name).build();
        cmd.push_param(keys);
        cmd.push_param("Enter");

        self.tmux()
            .command(cmd)
            .output()
            .expect("failed to send keys");
    }

    fn capture_pane(&self) -> String {
        let output = self
            .tmux()
            .command(CapturePane::new().stdout().target_pane(&self.session_name))
            .stdout(Some(StdIO::Piped))
            .output()
            .expect("failed to capture pane");
        String::from_utf8_lossy(&output.0.stdout).to_string()
    }

    /// Poll until marker appears in pane output.
    /// Markers are base64 encoded in commands, so they only appear once (decoded) in output.
    fn wait_for_marker(&self, marker: &str) {
        retry(100, || {
            let content = self.capture_pane();
            if content.contains(marker) {
                Ok(())
            } else {
                Err(content)
            }
        })
        .map_err(|content| anyhow::anyhow!("marker '{}' never appeared in pane: {content}", marker))
        .unwrap();
    }
}

impl Drop for TestEnv {
    fn drop(&mut self) {
        let _ = self._server.kill();
        let _ = self._server.wait();
    }
}

fn retry<T, E>(max_attempts: u32, mut f: impl FnMut() -> Result<T, E>) -> Result<T, E> {
    let mut last_err = None;
    for _ in 0..max_attempts {
        match f() {
            Ok(val) => return Ok(val),
            Err(e) => {
                last_err = Some(e);
                std::thread::sleep(Duration::from_millis(10));
            }
        }
    }
    Err(last_err.unwrap())
}

#[test]
fn test_status_line_empty() {
    let env = TestEnv::new("empty");

    env.status_line().stdout(predicate::str::is_empty());
}

#[test]
fn test_hook_creates_working_status() {
    let env = TestEnv::new("working");

    env.run_hook(
        // json
        r#"{ "hook_event_name": "UserPromptSubmit" }"#,
    );

    env.status_line()
        .stdout(predicate::str::contains("working"));
}

#[test]
fn test_hook_stop_sets_done() {
    let env = TestEnv::new("stop");

    env.run_hook(
        // json
        r#"{ "hook_event_name": "UserPromptSubmit" }"#,
    );

    env.run_hook(
        // json
        r#"{ "hook_event_name": "Stop" }"#,
    );

    env.status_line().stdout(predicate::str::contains("idle"));
}

#[test]
fn test_notification_idle_prompt_sets_done() {
    let env = TestEnv::new("idle");

    env.run_hook(
        // json
        r#"{ "hook_event_name": "Notification", "notification_type": "idle_prompt" }"#,
    );

    env.status_line().stdout(predicate::str::contains("idle"));
}

#[test]
fn test_notification_permission_prompt_sets_waiting() {
    let env = TestEnv::new("waiting");

    env.run_hook(
        // json
        r#"{ "hook_event_name": "Notification", "notification_type": "permission_prompt" }"#,
    );

    env.status_line()
        .stdout(predicate::str::contains("waiting"));
}
