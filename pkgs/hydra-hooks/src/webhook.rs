use axum::{
    body::{self, Body, Bytes},
    http::{Request, StatusCode},
    middleware::Next,
    response::IntoResponse,
};
use hmac::{Hmac, Mac};
use secrecy::{ExposeSecret, SecretString};
use sha2::Sha256;

use crate::AppError;

pub fn valid_signature(secret: &SecretString, payload: &str, expected: &[u8]) -> bool {
    let mut mac = Hmac::<Sha256>::new_from_slice(secret.expose_secret().as_bytes())
        .expect("HMAC can take key of any size");
    mac.update(payload.as_bytes());
    mac.verify_slice(expected).is_ok()
}

// middleware that shows how to consume the request body upfront
pub async fn print_request_body(
    request: Request<Body>,
    next: Next,
) -> Result<impl IntoResponse, AppError> {
    let request = buffer_request_body(request).await?;
    Ok(next.run(request).await)
}

// the trick is to take the request apart, buffer the body, do what you need to do, then put
// the request back together
async fn buffer_request_body(request: Request<Body>) -> Result<Request<Body>, AppError> {
    let (parts, body) = request.into_parts();
    parts
        .headers
        .get("X-Hub-Signature-256")
        .ok_or_else(|| (StatusCode::BAD_REQUEST, "Missing signature"))?;

    // this wont work if the body is an long running stream
    let bytes = body::to_bytes(body, 1024 * 1024)
        .await
        .map_err(|err| (StatusCode::BAD_REQUEST, err.to_string()))?;

    do_thing_with_request_body(bytes.clone());

    Ok(Request::from_parts(parts, Body::from(bytes)))
}

fn do_thing_with_request_body(bytes: Bytes) {
    tracing::warn!(body = ?bytes);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_example() {
        let sig = hex::decode("757107ea0eb2509fc211221cce984b8a37570b6d7586c22c46f4379c8b043e17")
            .unwrap();
        let secret = SecretString::new("It's a Secret to Everybody".into());
        assert!(valid_signature(&secret, "Hello, World!", &sig));
        assert!(!valid_signature(&secret, "Hello, World!", &[0; 32]));
    }
}
