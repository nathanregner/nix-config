use crate::app::UserEvent;
use crate::rate_limiter::RateLimiter;
use crate::{app::Application, notification::NotificationManager};
use backon::{ExponentialBuilder, Retryable};
use futures_util::{SinkExt, StreamExt};
use hydra_sentinel::{shutdown_signal, SentinelMessage};
use serde::Deserialize;
use std::time::Duration;
use tokio::sync::{oneshot, watch};
use tokio_tungstenite::{connect_async, tungstenite::protocol::Message};
use tracing::event;
use winit::event_loop::{self, EventLoop, EventLoopBuilder};

mod app;
mod notification;
mod rate_limiter;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Config {
    server_addr: String,
    host_name: String,
    #[serde(
        with = "humantime_serde",
        default = "Config::default_heartbeat_interval"
    )]
    heartbeat_interval: Duration,
}

impl Config {
    fn default_heartbeat_interval() -> Duration {
        Duration::from_secs(30)
    }
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
enum ConnectionState {
    Connected { keep_awake: bool },
    Disconnected,
}

fn main() -> anyhow::Result<()> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()?;
    let (connection_state_tx, connection_state_rx) = watch::channel(ConnectionState::Disconnected);
    let (enabled_tx, enabled_rx) = watch::channel(true);
    let (shutdown_tx, shutdown_rx) = oneshot::channel::<()>();
    rt.spawn(spawn(shutdown_tx, connection_state_tx, enabled_rx));
    rt.block_on(async move { Application::run(shutdown_rx, connection_state_rx, enabled_tx) })
}

async fn spawn(
    shutdown_tx: oneshot::Sender<()>,
    connection_state_tx: watch::Sender<ConnectionState>,
    enabled_rx: watch::Receiver<bool>,
) -> anyhow::Result<()> {
    let config = hydra_sentinel::init::<Config>(&format!("{}=DEBUG", module_path!()))?;

    let reconnect = RateLimiter::new(Duration::from_secs(30));
    let run = async move {
        loop {
            reconnect
                .throttle(|| run(&config, &connection_state_tx, &enabled_rx))
                .await?;
        }
        #[allow(unreachable_code)]
        anyhow::Ok(())
    };

    let shutdown = shutdown_signal();
    let res = tokio::select! {
        r = run => r,
        _ = shutdown => Ok(()),
    };
    drop(shutdown_tx);
    res
}

async fn run(
    config: &Config,
    connection_state_tx: &watch::Sender<ConnectionState>,
    enabled_rx: &watch::Receiver<bool>,
) -> anyhow::Result<()> {
    let connection_state_rx = connection_state_tx.subscribe();
    let (mut sender, mut receiver) = (|| async move {
        tracing::info!("Connecting to server: {}...", config.server_addr);
        let (stream, _response) = connect_async(format!(
            "ws://{}/ws?host_name={}",
            config.server_addr, config.host_name
        ))
        .await?;
        let _ = connection_state_tx.send(ConnectionState::Connected { keep_awake: false });
        tracing::info!("Connected");
        anyhow::Ok(stream)
    })
    .retry(
        &ExponentialBuilder::default()
            .with_max_delay(Duration::from_secs(15))
            .without_max_times()
            .with_jitter(),
    )
    .notify(|err, dur| {
        tracing::warn!(?err, "Connect failed, retrying in {dur:?}");
        let _ = connection_state_tx.send(ConnectionState::Disconnected);
    })
    .await?
    .split();

    let send = async move {
        let mut interval = tokio::time::interval(config.heartbeat_interval);
        loop {
            interval.tick().await;
            sender.send(Message::Ping(Default::default())).await?;
        }
        #[allow(unreachable_code)]
        anyhow::Ok(())
    };

    let recv = async move {
        while let Some(msg) = receiver.next().await {
            match msg? {
                Message::Text(msg) => {
                    let keep_awake = match SentinelMessage::try_from(msg.as_str()) {
                        Ok(SentinelMessage::KeepAwake(awake)) => awake,
                        Err(err) => {
                            tracing::warn!(?msg, ?err, "Failed to parse message");
                            continue;
                        }
                    };
                    let _ = connection_state_tx.send(ConnectionState::Connected { keep_awake });
                }
                Message::Close(_) => {
                    let _ = connection_state_tx.send(ConnectionState::Disconnected);
                    anyhow::bail!("Server closed connection");
                }
                Message::Ping(_) => {}
                Message::Pong(_) => {}
                Message::Frame(_) => {}
                Message::Binary(_) => {}
            };
        }

        Err(anyhow::anyhow!("End of stream"))
    };

    let mut enabled_rx = enabled_rx.clone();
    let mut connection_state_rx = connection_state_rx.clone();
    let keep_awake = async move {
        let mut awake_handle = None;
        loop {
            tokio::select! {
                _ = enabled_rx.changed() => {},
                _ = connection_state_rx.changed() => {},
            };
            let keep_awake = matches!(
                *connection_state_rx.borrow(),
                ConnectionState::Connected { keep_awake: true }
            );
            if keep_awake != awake_handle.is_some() {
                if keep_awake {
                    tracing::info!("Server requested keep-awake");
                    awake_handle = Some(
                        keepawake::Builder::default()
                            .display(false)
                            .idle(true)
                            .sleep(true)
                            .reason("Build queued")
                            .app_name("Nix Hydra Builder")
                            .app_reverse_domain("net.nregner.hydra-util")
                            .create()?,
                    );
                } else {
                    tracing::info!("Server cancelled keep-awake");
                    awake_handle = None;
                }
            }
        }
    };

    tokio::select! {
        r = send => r,
        r = recv => r,
        r = keep_awake => r,
    }
}
