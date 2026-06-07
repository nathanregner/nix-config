use std::time::{Duration, Instant};

use nix_gc_roots::{cache, nix};
use stumpalo::Arena;

fn main() -> anyhow::Result<()> {
    let arena = Arena::new();
    let duration_secs: u64 = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(10);

    eprintln!("Fetching firefox path-info --derivation...");
    let paths = nix::path_info(true, ["nixpkgs#firefox"])?;
    eprintln!("Got {} store paths", paths.len());

    let slice = cache::serialize(&arena, &paths)?;
    eprintln!("Serialized size: {} bytes", slice.as_slice().len());

    let duration = Duration::from_secs(duration_secs);
    eprintln!("Running access for {duration_secs}s...");

    let start = Instant::now();
    let mut iterations = 0u64;

    while start.elapsed() < duration {
        let archived = cache::access(slice.as_slice()).expect("Failed to access");
        std::hint::black_box(archived.len());
        iterations += 1;
    }

    eprintln!("Ran {iterations} iterations in {:?}", start.elapsed());
    Ok(())
}
