use std::{
    collections::{HashMap, HashSet},
    ops::Deref,
    path::{Path, PathBuf},
    sync::{
        Arc,
        atomic::{self, AtomicU32},
    },
    time::SystemTime,
};

use anyhow::{Context, Result};
use heed::{WithTls, types};
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use rkyv::{Archive, Deserialize as RkyvDeserialize, Serialize as RkyvSerialize, rancor::Error};
use serde::{Deserialize, Serialize};

use crate::{
    nix::{GcRoot, path_info},
    types::{ArchivedBytes, StorePath},
};

#[derive(Clone, Copy, Debug)]
pub enum LoadProgress {
    GcRoots,
    PathInfo { done: u32, total: u32 },
    BuildGraph,
}

pub struct Cache {
    env: heed::Env<WithTls>,
    db: heed::Database<types::Bytes, types::Bytes>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct GcRootWithSize {
    pub symlink: PathBuf,
    pub modified: SystemTime,
    pub store_path: PathBuf,
    pub nar_size: Option<u64>,
}

pub struct GcRootClosure {
    pub root: GcRoot,
    pub path_info: Arc<PathInfoMap>,
}

impl Deref for GcRootClosure {
    type Target = GcRoot;

    fn deref(&self) -> &Self::Target {
        &self.root
    }
}

impl Cache {
    pub fn new(path: &Path) -> Result<Self> {
        let env = unsafe {
            heed::EnvOpenOptions::new()
                .map_size(10 * 1024 * 1024 * 1024)
                .open(path)
        }
        .with_context(|| format!("Failed to open {path:?}"))?;
        let mut txn = env.write_txn().context("Failed to start write txn")?;
        let db = env.create_database(&mut txn, None)?;
        txn.commit()?;
        Ok(Self { env, db })
    }

    pub fn get_path_info(
        &self,
        roots: Vec<GcRoot>,
        on_progress: impl Fn(LoadProgress) + Sync,
    ) -> Result<Vec<GcRootClosure>> {
        let store_paths = roots
            .iter()
            .map(|root| root.store_path.clone())
            .collect::<HashSet<_>>();

        let cached = self.get_all(&store_paths)?;

        let to_lookup = store_paths
            .into_iter()
            .filter(|store_path| !cached.contains_key(store_path.as_path()))
            .collect::<Vec<_>>();

        let total = to_lookup.len() as u32;
        on_progress(LoadProgress::PathInfo { done: 0, total });
        let counter = Arc::new(AtomicU32::new(0));

        let uncached = to_lookup
            .into_par_iter()
            .map_with(counter, |counter, store_path| {
                let path_info = path_info(false, [&store_path])
                    .with_context(|| format!("Failed to compute path-info for {store_path:?}"))?;
                let done = counter.fetch_add(1, atomic::Ordering::Relaxed) + 1;
                on_progress(LoadProgress::PathInfo { done, total });
                Ok((store_path, path_info))
            })
            // TODO: batched
            .collect::<Result<HashMap<_, _>>>()?;

        self.put_all(&uncached)?;
        let mut merged = HashMap::with_capacity(cached.len() + uncached.len());
        for (store_path, path_info) in uncached {
            merged.insert(store_path, Arc::new(path_info));
        }
        for (store_path, path_info) in cached {
            merged.insert(store_path, Arc::new(path_info));
        }

        let mut result = Vec::with_capacity(roots.len());
        for root in roots {
            let path_info = merged
                .get(&root.store_path)
                .ok_or_else(|| anyhow::anyhow!("Missing path_info for {:?}", root.store_path))?
                .clone();
            result.push(GcRootClosure { root, path_info });
        }

        Ok(result)
    }

    pub fn get_all(&self, paths: &HashSet<PathBuf>) -> Result<HashMap<PathBuf, PathInfoMap>> {
        let txn = self.env.read_txn().context("Failed to start read txn")?;

        let get_one = |path: &Path| {
            let Some(data) = self.db.get(&txn, path.as_os_str().as_encoded_bytes())? else {
                return anyhow::Ok(None);
            };
            // TODO: don't copy if aligned
            // TODO: reuse buffer
            let archived = ArchivedBytes::<PathInfoMap>::from_bytes(data)?;
            let path_info = rkyv::deserialize::<_, Error>(archived.deref())?;
            Ok(Some(path_info))
        };

        let entries = paths
            .iter()
            .filter_map(|path| match get_one(path) {
                Ok(archived) => Some((path.clone(), archived?)),
                Err(err) => {
                    eprintln!("Failed to load cached path info {path:?}: {err}");
                    None
                }
            })
            .collect::<HashMap<_, _>>();
        txn.commit().context("Failed to commit read txn")?;
        Ok(entries)
    }

    pub fn put_all(&self, paths: &HashMap<PathBuf, PathInfoMap>) -> Result<()> {
        if paths.is_empty() {
            return Ok(());
        }
        let mut txn = self.env.write_txn().context("Failed to start write txn")?;
        for (path, path_info) in paths {
            let path_info = ArchivedBytes::from_value(path_info)
                .context("Failed to serialize path_info for {store_path:?}")?;

            self.db
                .put(
                    &mut txn,
                    path.as_os_str().as_encoded_bytes(),
                    path_info.as_slice(),
                )
                .with_context(|| format!("Failed to write {path:?} to cache"))?;
        }
        txn.commit().context("Failed to commit write txn")?;
        Ok(())
    }
}

#[derive(Archive, RkyvSerialize, RkyvDeserialize, Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct PathInfo {
    pub nar_size: u64,
    pub references: Vec<StorePath>,
}

pub type PathInfoMap = HashMap<StorePath, PathInfo>;
