use std::os::unix::ffi::OsStrExt;

use criterion::{Criterion, criterion_group, criterion_main};
use heed::EnvOpenOptions;
use heed::types::Bytes;
use nix_gc_roots::{
    cache::{self, ArchivedPathInfoMap},
    nix,
    types::OwnedArchive,
};
use tempfile::TempDir;

fn fetch_firefox_derivation() -> anyhow::Result<cache::PathInfoMap> {
    eprintln!("Fetching firefox path-info --derivation...");
    let paths = nix::path_info(true, ["nixpkgs#firefox"])?;
    eprintln!("Got {} store paths", paths.len());
    Ok(paths)
}

fn access(buf: &[u8]) -> Result<&ArchivedPathInfoMap, rkyv::rancor::Error> {
    rkyv::access(buf)
}

fn setup_cache() -> (TempDir, Vec<u8>, OwnedArchive<ArchivedPathInfoMap>) {
    let paths = fetch_firefox_derivation().expect("Failed to fetch derivation");

    let tmpdir = TempDir::new().expect("Failed to create temp dir");
    let cache_path = tmpdir.path().to_path_buf();

    let serialized = cache::serialize(&paths);
    eprintln!("rkyv size: {} bytes", serialized.as_slice().len());

    let store_path = paths
        .keys()
        .next()
        .unwrap()
        .0
        .as_os_str()
        .as_bytes()
        .to_vec();

    {
        let env = unsafe {
            EnvOpenOptions::new()
                .map_size(1024 * 1024 * 1024)
                .open(&cache_path)
        }
        .expect("Failed to open env");

        let mut txn = env.write_txn().expect("Failed to start txn");
        let db = env
            .create_database::<Bytes, Bytes>(&mut txn, None)
            .expect("Failed to create db");
        db.put(&mut txn, &store_path, serialized.as_slice())
            .expect("Failed to put");
        txn.commit().expect("Failed to commit");
    }

    (tmpdir, store_path, serialized)
}

fn bench_cache(c: &mut Criterion) {
    let (tmpdir, store_path, serialized) = setup_cache();
    let cache_path = tmpdir.path();

    let mut group = c.benchmark_group("cache");

    let env = unsafe {
        EnvOpenOptions::new()
            .map_size(1024 * 1024 * 1024)
            .open(cache_path)
    }
    .expect("Failed to open env");

    let txn = env.read_txn().expect("Failed to start txn");
    let db = env
        .open_database::<Bytes, Bytes>(&txn, None)
        .expect("Failed to open db")
        .expect("No db");

    group.bench_function("lmdb read + rkyv access", |b| {
        b.iter(|| {
            let data = db
                .get(&txn, &store_path)
                .expect("Failed to get")
                .expect("No data");
            let archived = access(data).expect("Failed to access");
            std::hint::black_box(archived.len());
        });
    });

    group.finish();
}

criterion_group!(benches, bench_cache);
criterion_main!(benches);
