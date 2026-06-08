use std::collections::HashMap;
use std::collections::HashSet;
use std::ops::Deref;
use std::path::Path;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{self, AtomicU32};
use std::time::SystemTime;

use anyhow::{Context, Result};
use heed::{WithTls, types};
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use rkyv::collections::swiss_table::ArchivedHashMap;
use rkyv::hash::FxHasher64;
use rkyv::rancor::Error as RkyvError;
use rkyv::util::AlignedVec;
use rkyv::{Archive, Deserialize as RkyvDeserialize, Serialize as RkyvSerialize};
use serde::{Deserialize, Serialize};

use crate::nix::{GcRoot, path_info};
use crate::types::{ArchivedStorePath, OwnedArchive, StorePath};

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

pub struct GcRootWithPaths {
    root: GcRoot,
    pub path_info: OwnedArchive<ArchivedPathInfoMap>,
}

impl Deref for GcRootWithPaths {
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

    pub fn build_graph(&self, roots: Vec<GcRoot>) -> Result<Vec<GcRootWithPaths>> {
        let store_paths = roots
            .iter()
            .map(|root| root.store_path.clone())
            .collect::<HashSet<_>>();
        let cached = self.get_all(&store_paths)?;
        eprintln!("Cached {}", cached.len());

        let to_compute = store_paths
            .into_iter()
            .filter(|store_path| !cached.contains_key(store_path.as_path()))
            .collect::<Vec<_>>();

        let total = to_compute.len();
        let counter = Arc::new(AtomicU32::new(0));

        let uncached = to_compute
            .into_par_iter()
            .map_with(counter, |counter, store_path| {
                let nix_path_info = path_info(false, [&store_path])
                    .with_context(|| format!("Failed to compute path-info for {store_path:?}"))?;
                let progress = counter.fetch_add(1, atomic::Ordering::Relaxed) + 1;
                eprintln!("path_info ({:?}) {}/{}", store_path, progress, total);
                anyhow::Ok((store_path, nix_path_info))
            })
            // TODO: batched
            .collect::<Result<HashMap<_, _>>>()?;

        let uncached = uncached
            .into_iter()
            .map(|(store_path, paths)| (store_path, serialize(&paths)))
            .collect::<HashMap<_, _>>();

        // eprintln!("Uncached {}", uncached.len());
        self.put_all(&uncached)?;
        let mut merged = HashMap::with_capacity(cached.len() + uncached.len());
        for (store_path, path_info) in uncached {
            merged.insert(store_path, path_info);
        }
        for (store_path, path_info) in cached {
            merged.insert(store_path, path_info);
        }

        let mut result = Vec::with_capacity(roots.len());
        for root in roots {
            let path_info = merged
                .get(&root.store_path)
                .ok_or_else(|| anyhow::anyhow!("Missing path_info for {:?}", root.store_path))?
                .clone();
            result.push(GcRootWithPaths { root, path_info });
        }

        Ok(result)
    }

    fn get_all(
        &self,
        paths: &HashSet<PathBuf>,
    ) -> Result<HashMap<PathBuf, OwnedArchive<ArchivedPathInfoMap>>> {
        let txn = self.env.read_txn().context("Failed to start read txn")?;
        let entries = paths
            .iter()
            .filter_map(
                |path| match self.db.get(&txn, path.as_os_str().as_encoded_bytes()) {
                    Ok(Some(data)) => {
                        let mut bytes = AlignedVec::<16>::with_capacity(data.len());
                        bytes.extend_from_slice(data);
                        match OwnedArchive::from_bytes(bytes) {
                            Ok(archived) => Some((path.clone(), archived)),
                            Err(err) => {
                                eprintln!("Failed to load cached path info {path:?}: {err}");
                                None
                            }
                        }
                    }
                    Ok(None) => None,
                    Err(err) => {
                        eprintln!("Failed to load cached path info {path:?}: {err}");
                        None
                    }
                },
            )
            .collect::<HashMap<_, _>>();
        txn.commit().context("Failed to commit read txn")?;
        Ok(entries)
    }

    fn put_all(&self, paths: &HashMap<PathBuf, OwnedArchive<ArchivedPathInfoMap>>) -> Result<()> {
        if paths.is_empty() {
            return Ok(());
        }
        let mut txn = self.env.write_txn().context("Failed to start write txn")?;
        for (path, data) in paths {
            self.db
                .put(
                    &mut txn,
                    path.as_os_str().as_encoded_bytes(),
                    data.as_slice(),
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

pub type ArchivedPathInfoMap = ArchivedHashMap<ArchivedStorePath, ArchivedPathInfo, FxHasher64>;

pub fn serialize(paths: &PathInfoMap) -> OwnedArchive<ArchivedPathInfoMap> {
    let bytes = rkyv::to_bytes::<RkyvError>(paths).expect("serialization should not fail");
    OwnedArchive::from_bytes_unchecked(bytes)
}
