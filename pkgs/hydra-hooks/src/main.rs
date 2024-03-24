mod webhook;

use axum::{
    http::StatusCode,
    middleware,
    response::{IntoResponse, Response},
    routing::post,
    Json, Router,
};
use listenfd::ListenFd;
use serde_json::Value;
use std::borrow::Cow;
use tokio::net::TcpListener;

use tower_http::trace::{DefaultMakeSpan, TraceLayer};

use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // build our application with some routes
    let app = Router::new()
        // .route("/ws", get(ws_handler))
        // logging so we can see whats going on
        .route(
            "/webhook",
            post(webhook).route_layer(middleware::from_fn(webhook::print_request_body)),
        )
        .layer(TraceLayer::new_for_http().make_span_with(DefaultMakeSpan::default()));

    let mut listenfd = ListenFd::from_env();
    let listener = match listenfd.take_tcp_listener(0).unwrap() {
        // if we are given a tcp listener on listen fd 0, we use that one
        Some(listener) => {
            listener.set_nonblocking(true).unwrap();
            TcpListener::from_std(listener).unwrap()
        }
        // otherwise fall back to local listening
        None => TcpListener::bind("127.0.0.1:3000").await.unwrap(),
    };

    tracing::debug!("listening on {}", listener.local_addr()?);
    axum::serve(listener, app).await?;
    Ok(())
}

#[axum::debug_handler]
async fn webhook(body: Json<Value>) -> Result<(), ()> {
    dbg!(body);
    Ok(())
}

#[derive(Debug)]
enum AppError {
    StatusCodeMessage(StatusCode, Cow<'static, str>),
    InternalServerError(anyhow::Error),
}

impl<S> From<(StatusCode, S)> for AppError
where
    S: Into<Cow<'static, str>>,
{
    fn from((status, message): (StatusCode, S)) -> Self {
        AppError::StatusCodeMessage(status, message.into())
    }
}

impl From<anyhow::Error> for AppError {
    fn from(e: anyhow::Error) -> Self {
        AppError::InternalServerError(e)
    }
}

// Tell axum how `AppError` should be converted into a response.
//
// This is also a convenient place to log errors.
impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        match self {
            AppError::InternalServerError(err) => {
                tracing::error!(%err, "Internal server error");
                StatusCode::INTERNAL_SERVER_ERROR.into_response()
            }
            AppError::StatusCodeMessage(status, message) => {
                tracing::error!(%status, %message);
                (status, message).into_response()
            }
        }
    }
}
