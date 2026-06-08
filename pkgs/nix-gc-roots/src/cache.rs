use std::collections::HashMap;
use std::collections::HashSet;
use std::ops::Deref;
use std::path::Path;
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic;
use std::sync::atomic::AtomicU32;
use std::time::SystemTime;

use anyhow::Context;
use anyhow::Result;
use heed::WithTls;
use heed::types;
use rayon::iter::IntoParallelIterator;
use rayon::iter::ParallelIterator;
use rkyv::collections::swiss_table::ArchivedHashMap;
use rkyv::hash::FxHasher64;
use rkyv::rancor::Error as RkyvError;
use rkyv::{Archive, Deserialize as RkyvDeserialize, Serialize as RkyvSerialize};
use serde::{Deserialize, Serialize};
use stumpalo::Arena;

use crate::nix::GcRoot;
use crate::nix::path_info;
use crate::types::ArchivedSlice;
use crate::types::ArchivedStorePath;
use crate::types::StorePath;

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

pub struct GcRootWithPaths<'a> {
    root: GcRoot,
    pub path_info: ArchivedSlice<'a, ArchivedPathInfoMap>,
}

impl Deref for GcRootWithPaths<'_> {
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

    pub fn build_graph<'a>(
        &self,
        arena: &'a Arena,
        roots: Vec<GcRoot>,
    ) -> Result<Vec<GcRootWithPaths<'a>>> {
        let store_paths = roots
            .iter()
            .map(|root| root.store_path.clone())
            .collect::<HashSet<_>>();
        let cached = self.get_all(arena, &store_paths)?;
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
            .map(|(store_path, paths)| Ok((store_path, serialize(arena, &paths)?)))
            .collect::<Result<HashMap<_, _>>>()?;

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
                .get(&*root.store_path)
                .ok_or_else(|| anyhow::anyhow!("Missing path_info for {:?}", root.store_path))?
                .clone();
            result.push(GcRootWithPaths { root, path_info });
        }

        Ok(result)
    }

    fn get_all<'a>(
        &self,
        arena: &'a Arena,
        paths: &HashSet<PathBuf>,
    ) -> Result<HashMap<PathBuf, ArchivedSlice<'a, ArchivedPathInfoMap>>> {
        let txn = self.env.read_txn().context("Failed to start read txn")?;
        let entries = paths
            .iter()
            .filter_map(
                |path| match self.db.get(&txn, path.as_os_str().as_encoded_bytes()) {
                    Ok(Some(data)) => {
                        let bytes = alloc_aligned_8(arena, data);
                        match ArchivedSlice::new(bytes) {
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

    fn put_all<'a>(
        &self,
        paths: &HashMap<PathBuf, ArchivedSlice<'a, ArchivedPathInfoMap>>,
    ) -> Result<()> {
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

pub fn serialize<'a>(
    arena: &'a Arena,
    paths: &PathInfoMap,
) -> Result<ArchivedSlice<'a, ArchivedPathInfoMap>> {
    // FIXME: intermediate allocation, do we care?
    let to_bytes = rkyv::to_bytes::<RkyvError>(paths)?;
    let bytes = alloc_aligned_8(arena, &to_bytes);
    Ok(ArchivedSlice::new(bytes)?)
}

// TODO: expose alloc_layout in stumpalo to avoid zero+copy
fn alloc_aligned_8<'a>(arena: &'a Arena, src: &[u8]) -> &'a [u8] {
    let u64_len = src.len().div_ceil(8);
    let storage = arena.alloc_slice_fill_with(u64_len, |_| 0u64);
    debug_assert_eq!(
        storage.as_ptr() as usize % 8,
        0,
        "stumpalo didn't align u64 slice"
    );
    unsafe {
        std::ptr::copy_nonoverlapping(src.as_ptr(), storage.as_mut_ptr().cast::<u8>(), src.len());
        std::slice::from_raw_parts(storage.as_ptr().cast::<u8>(), src.len())
    }
}
