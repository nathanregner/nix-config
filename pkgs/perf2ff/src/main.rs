//! https://github.com/firefox-devtools/profiler/blob/main/docs-developer/loading-in-profiles.md#url

use std::io::{Cursor, Read};
use std::net::{Ipv4Addr, SocketAddr};
use std::path::PathBuf;
use std::process::Command;
use std::str::FromStr;
use std::sync::Arc;
use std::{env, io};

use anyhow::Context;
use http_body_util::Full;
use hyper::body::{Bytes, Incoming};
use hyper::header::{HeaderValue, ACCESS_CONTROL_ALLOW_ORIGIN};
use hyper::service::service_fn;
use hyper::{Request, Response};
use hyper_util::rt::{TokioExecutor, TokioIo};
use rustls::pki_types::{CertificateDer, PrivateKeyDer};
use rustls::ServerConfig;
use tokio::net::TcpListener;
use tokio_rustls::TlsAcceptor;
use url::Url;

fn main() -> anyhow::Result<()> {
    run_server()
}

#[tokio::main(flavor = "current_thread")]
async fn run_server() -> anyhow::Result<()> {
    let addr = SocketAddr::new(Ipv4Addr::LOCALHOST.into(), 9999);

    let certs = load_cert()?;
    let key = load_private_key()?;

    let incoming = TcpListener::bind(&addr).await?;

    let port = incoming.local_addr().expect("address was not bound").port();

    let server_config = ServerConfig::builder()
        .with_no_client_auth()
        .with_single_cert(certs, key)?;
    let tls_acceptor = TlsAcceptor::from(Arc::new(server_config));

    open_firefox_profiler(port)?;

    let (tcp_stream, _remote_addr) = incoming.accept().await?;

    let tls_acceptor = tls_acceptor.clone();
    let tls_stream = tls_acceptor.accept(tcp_stream).await?;

    if let Err(err) = hyper_util::server::conn::auto::Builder::new(TokioExecutor::new())
        .serve_connection(TokioIo::new(tls_stream), service_fn(serve))
        .await
    {
        anyhow::bail!("{err}");
    }

    Ok(())
}

async fn serve(_req: Request<Incoming>) -> Result<Response<Full<Bytes>>, hyper::Error> {
    let perf_data = load_perf_data().await.expect("failed to load perf data");

    let mut response = Response::new(Full::new(Bytes::from(perf_data)));
    let headers = response.headers_mut();
    headers.insert(
        ACCESS_CONTROL_ALLOW_ORIGIN,
        HeaderValue::from_static("https://profiler.firefox.com"),
    );
    // headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
    Ok(response)
}

fn load_cert() -> io::Result<Vec<CertificateDer<'static>>> {
    let mut reader = Cursor::new(include_bytes!("../localhost.cert"));
    rustls_pemfile::certs(&mut reader).collect()
}

fn load_private_key() -> io::Result<PrivateKeyDer<'static>> {
    let mut reader = Cursor::new(include_bytes!("../localhost.key"));
    rustls_pemfile::private_key(&mut reader).map(|key| key.unwrap())
}

async fn load_perf_data() -> anyhow::Result<Vec<u8>> {
    if let Some(path) = env::args().nth(1) {
        let path = PathBuf::from_str(&path).with_context(|| format!("parsing path {path}"))?;
        println!("loading file: {path:?}");
        Ok(std::fs::read(path)?)
    } else {
        let mut buf = vec![];
        std::io::stdin().read_to_end(&mut buf)?;
        Ok(buf)
    }
}

fn open_firefox_profiler(port: u16) -> anyhow::Result<()> {
    let mut url = Url::parse("https://profiler.firefox.com/from-url/")?;
    url.path_segments_mut()
        .expect("base url")
        .push(&format!("https://localhost:{port}"));
    Command::new("firefox")
        .arg(url.to_string())
        .spawn()?
        .wait()?;
    Ok(())
}

// type DynAsyncRead = Box<dyn AsyncRead + Unpin + Send>;
//
// async fn load_perf_data_stream() -> anyhow::Result<DynAsyncRead> {
//     Ok(if let Some(path) = env::args().nth(1) {
//         let path = PathBuf::from_str(&path).with_context(|| format!("parsing path {path}"))?;
//         Box::new(
//             File::open(&path)
//                 .await
//                 .with_context(|| format!("reading {path:?}"))?,
//         )
//     } else {
//         Box::new(tokio::io::stdin())
//     })
// }
