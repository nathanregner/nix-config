use criterion::{Criterion, criterion_group, criterion_main};
use heed::EnvOpenOptions;
use heed::types::Bytes;
use nix_gc_roots::{cache, nix};
use stumpalo::Arena;
use tempfile::TempDir;

fn fetch_firefox_derivation() -> anyhow::Result<cache::PathInfoMap> {
    eprintln!("Fetching firefox path-info --derivation...");
    let paths = nix::path_info(true, ["nixpkgs#firefox"])?;
    eprintln!("Got {} store paths", paths.len());
    Ok(paths)
}

fn setup_cache(arena: &Arena) -> (TempDir, String, &[u8]) {
    let paths = fetch_firefox_derivation().expect("Failed to fetch derivation");

    let tmpdir = TempDir::new().expect("Failed to create temp dir");
    let cache_path = tmpdir.path().to_path_buf();

    let serialized = cache::serialize(arena, &paths).expect("Failed to serialize");
    eprintln!("rkyv size: {} bytes", serialized.len());

    let store_path = paths.keys().next().unwrap().clone();

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
        db.put(&mut txn, store_path.as_bytes(), serialized.as_slice())
            .expect("Failed to put");
        txn.commit().expect("Failed to commit");
    }

    (tmpdir, store_path, serialized.as_slice())
}

fn bench_cache(c: &mut Criterion) {
    let arena = Arena::new();
    let (tmpdir, store_path, serialized) = setup_cache(&arena);
    let cache_path = tmpdir.path();

    let mut group = c.benchmark_group("cache");

    group.bench_function("rkyv access (in-memory)", |b| {
        b.iter(|| {
            let archived = cache::access(serialized).expect("Failed to access");
            std::hint::black_box(archived.len());
        });
    });

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
                .get(&txn, store_path.as_bytes())
                .expect("Failed to get")
                .expect("No data");
            let archived = cache::access(data).expect("Failed to access");
            std::hint::black_box(archived.len());
        });
    });

    group.finish();
}

criterion_group!(benches, bench_cache);
criterion_main!(benches);
