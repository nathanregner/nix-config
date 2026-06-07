use std::vec;

use criterion::{Criterion, criterion_group, criterion_main};
use nix_gc_roots::{
    cache,
    nix::{self, PathInfoMap},
};
use stumpalo::Arena;

// use firefox derivation, as it contains a significant number of dependencies
fn fetch_firefox_derivation() -> anyhow::Result<PathInfoMap> {
    eprintln!("Fetching firefox path-info --derivation...");
    let paths = nix::path_info(true, ["nixpkgs#firefox"])?;
    eprintln!("Got {} store paths", paths.len());

    Ok(paths)
}

fn bench_get_all(c: &mut Criterion) {
    let paths = fetch_firefox_derivation().expect("Failed to fetch derivation");

    let mut group = c.benchmark_group("cache");
    // group.measurement_time(std::time::Duration::from_secs(10));

    let mut buf = vec![];
    cache::serialize(&paths, &mut buf).expect("Failed to serialize");

    group.bench_function("deserialize", |b| {
        let mut arena = Arena::new();
        b.iter(|| {
            let result = cache::deserialize_arena(&arena, &buf).expect("Failed to deserialize");
            std::hint::black_box(&result);
            drop(result);
            arena.clear();
        });
    });

    group.finish();
}

criterion_group!(benches, bench_get_all);
criterion_main!(benches);
