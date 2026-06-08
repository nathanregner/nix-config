use std::time::{Duration, Instant};

use nix_gc_roots::{
    cache::{ArchivedPathInfoMap, PathInfoMap},
    nix,
    types::ArchivedBytes,
};

fn access(buf: &[u8]) -> Result<&ArchivedPathInfoMap, rkyv::rancor::Error> {
    rkyv::access(buf)
}

fn main() -> anyhow::Result<()> {
    let duration_secs: u64 = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(10);

    eprintln!("Fetching firefox path-info --derivation...");
    let paths = nix::path_info(true, ["nixpkgs#firefox"])?;
    eprintln!("Got {} store paths", paths.len());

    let owned = ArchivedBytes::<PathInfoMap>::from_value(&paths)?;
    eprintln!("Serialized size: {} bytes", owned.as_slice().len());

    let duration = Duration::from_secs(duration_secs);
    eprintln!("Running access for {duration_secs}s...");

    let start = Instant::now();
    let mut iterations = 0u64;

    while start.elapsed() < duration {
        let archived = access(owned.as_slice()).expect("Failed to access");
        std::hint::black_box(archived.len());
        iterations += 1;
    }

    eprintln!("Ran {iterations} iterations in {:?}", start.elapsed());
    Ok(())
}
