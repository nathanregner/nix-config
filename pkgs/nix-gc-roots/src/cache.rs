use std::ops::Deref;
use std::path::Path;
use std::sync::Arc;
use std::sync::atomic::{self, AtomicU32};
use std::sync::mpsc;
use std::thread;

use anyhow::{Context, Result};
use heed::RoTxn;
use heed::WithTls;
use heed::types::Bytes;
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use rustc_hash::FxHashMap;
use rustc_hash::FxHashSet;

use crate::nix::Installable;
use crate::nix::{GcRoot, path_info};
use crate::types::Aligned;
use crate::types::{ArchivedBytes, StorePath};

#[derive(Clone, Debug)]
pub enum LoadProgress {
    GcRoots,
    PathInfo { done: u32, total: u32 },
    BuildGraph,
    Error(String),
}

pub struct Cache {
    env: heed::Env<WithTls>, // TODO: no tls
    db: heed::Database<Bytes, Bytes>,
}

pub type ArchivedClosure<'a> = ArchivedBytes<'a, Aligned<Closure>>;

pub type ArchivedPathBuf<'a> = ArchivedBytes<'a, Aligned<StorePath>>;

pub struct GcRootClosure<'a> {
    pub root: GcRoot,
    pub closure: ArchivedClosure<'a>,
}

impl Deref for GcRootClosure<'_> {
    type Target = GcRoot;

    fn deref(&self) -> &Self::Target {
        &self.root
    }
}

impl Cache {
    // TODO: unify with CacheTxn?
    pub fn open(path: &Path) -> Result<Self> {
        let env = unsafe {
            heed::EnvOpenOptions::new()
                .map_size(64 * 1024 * 1024 * 1024) // should be more than enough... right?
                .open(path)
        }
        .with_context(|| format!("Failed to open {path:?}"))?;
        let mut txn = env.write_txn().context("Failed to start write txn")?;
        let db = env.create_database(&mut txn, None)?;
        txn.commit()?;
        Ok(Self { env, db })
    }

    pub fn txn<'a>(&'a self) -> Result<CacheTxn<'a>> {
        let txn = self.env.read_txn().context("Failed to start read txn")?;
        Ok(CacheTxn { cache: self, txn })
    }

    fn get_all<'a: 't, 't>(
        &self,
        txn: &'a RoTxn<'t, WithTls>,
        paths: &FxHashSet<ArchivedPathBuf<'static>>,
    ) -> Result<FxHashMap<ArchivedPathBuf<'static>, ArchivedClosure<'t>>> {
        let get_one = |store_path: &ArchivedPathBuf<'static>| {
            let Some(data) = self.db.get(txn, store_path.as_slice())? else {
                return anyhow::Ok(None);
            };
            let value = ArchivedClosure::from_bytes(data)?;
            Ok(Some((store_path.clone(), value)))
        };

        let entries = paths
            .iter()
            .filter_map(|path| match get_one(path).transpose()? {
                Ok(archived) => Some(archived),
                Err(err) => {
                    // TODO: log, propagate warn to TUI
                    eprintln!(
                        "Failed to load cached path info {:?}: {err}",
                        path.0.as_path()
                    );
                    None
                }
            })
            .collect::<FxHashMap<_, _>>();
        // txn.commit().context("Failed to commit read txn")?;
        Ok(entries)
    }

    fn put_all(&self, paths: &FxHashMap<ArchivedPathBuf, ArchivedClosure>) -> Result<()> {
        if paths.is_empty() {
            return Ok(());
        }
        let mut txn = self.env.write_txn().context("Failed to start write txn")?;
        for (path, path_info) in paths {
            self.db
                .put(&mut txn, path.as_slice(), path_info.as_slice())
                .with_context(|| format!("Failed to write {:?} to cache", path.0))?;
        }
        txn.commit().context("Failed to commit write txn")?;
        Ok(())
    }
}

pub struct CacheTxn<'a> {
    cache: &'a Cache,
    txn: RoTxn<'a, WithTls>,
}

impl<'a> CacheTxn<'a> {
    pub fn resolve(
        &'a self,
        roots: Vec<GcRoot>,
        on_progress: impl Fn(LoadProgress) + Sync,
    ) -> Result<Vec<GcRootClosure<'a>>> {
        let store_paths = roots
            .iter()
            .map(|root| {
                ArchivedPathBuf::from_value(&Aligned(StorePath(root.store_path.clone())))
                    .expect("Failed to serialize store_path")
            })
            .collect::<FxHashSet<_>>();

        let cached = self.cache.get_all(&self.txn, &store_paths)?;

        let to_lookup = store_paths
            .into_iter()
            .filter(|store_path| !cached.contains_key(store_path))
            .collect::<Vec<_>>();

        let total = to_lookup.len() as u32;
        on_progress(LoadProgress::PathInfo { done: 0, total });
        let counter = Arc::new(AtomicU32::new(0));

        fn resolve_one(
            key: ArchivedPathBuf<'static>,
        ) -> Result<(ArchivedPathBuf<'static>, ArchivedClosure<'static>)> {
            let store_path = key.0.to_path_buf();
            let closure = path_info(Installable::Output, [&store_path])?;
            let value = ArchivedClosure::from_value(&Aligned(closure))?;
            Ok((key, value))
        }

        // Writer thread batches entries and flushes without blocking workers
        const BATCH_SIZE: usize = 50;
        type Entry = (ArchivedPathBuf<'static>, ArchivedClosure<'static>);
        let (write_tx, write_rx) = mpsc::channel::<Entry>();
        let cache = &self.cache;
        let uncached = thread::scope(|s| {
            let writer_handle = s.spawn(|| {
                let mut batch = FxHashMap::default();
                for (k, v) in write_rx {
                    batch.insert(k, v);
                    if batch.len() >= BATCH_SIZE {
                        cache.put_all(&batch)?;
                        batch.clear();
                    }
                }
                if !batch.is_empty() {
                    cache.put_all(&batch)?;
                }
                anyhow::Ok(())
            });

            let uncached: Vec<Result<Entry>> = to_lookup
                .into_par_iter()
                .map(|store_path| {
                    let entry = resolve_one(store_path.clone())?;
                    let done = counter.fetch_add(1, atomic::Ordering::Relaxed) + 1;
                    on_progress(LoadProgress::PathInfo { done, total });
                    write_tx.send(entry.clone()).ok();
                    Ok(entry)
                })
                .collect();

            drop(write_tx);
            writer_handle.join().unwrap()?;

            let mut result = FxHashMap::default();
            for entry in uncached {
                let (k, v) = entry?;
                result.insert(k, v);
            }
            anyhow::Ok(result)
        })?;
        let mut merged =
            FxHashMap::with_capacity_and_hasher(cached.len() + uncached.len(), Default::default());
        for (store_path, path_info) in uncached {
            merged.insert(store_path, path_info);
        }
        for (store_path, path_info) in cached {
            merged.insert(store_path, path_info);
        }

        let mut result = Vec::with_capacity(roots.len());
        for root in roots {
            let key = ArchivedPathBuf::from_value(&Aligned(StorePath(root.store_path.clone())))?;
            let path_info = merged
                .get(&key)
                .ok_or_else(|| anyhow::anyhow!("Missing path_info for {:?}", root.store_path))?
                .clone();
            result.push(GcRootClosure {
                root,
                closure: path_info,
            });
        }

        Ok(result)
    }
}

#[derive(serde::Deserialize)] //
#[derive(rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)] //
#[serde(rename_all = "camelCase")]
pub struct PathInfo {
    pub nar_size: u64,
    pub references: Vec<StorePath>,
}

pub type Closure = FxHashMap<StorePath, PathInfo>;
