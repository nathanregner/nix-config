use std::collections::HashMap;
use std::collections::HashSet;
use std::io::Cursor;
use std::ops::Deref;
use std::path::Path;
use std::path::PathBuf;
use std::rc::Rc;
use std::time::SystemTime;

use anyhow::Context;
use anyhow::Result;
use heed::WithTls;
use heed::types;

use crate::nix::GcRoot;
use crate::nix::PathInfoMap;
use crate::nix::path_info;

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

#[derive(Debug)]
pub struct GcRootWithPaths {
    root: GcRoot,
    pub path_info: Rc<PathInfoMap>,
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
                // TODO: what should this be...
                .map_size(10 * 1024 * 1024 * 1024)
                .open(path)
        }
        .with_context(|| format!("Failed to open {path:?}"))?;
        let mut txn = env.write_txn().context("Failed to start write txn")?;
        let db = env.create_database(&mut txn, None)?;
        drop(txn);
        Ok(Self { env, db })
    }

    pub fn build_graph(&self, roots: Vec<GcRoot>) -> Result<Vec<GcRootWithPaths>> {
        let store_paths = roots
            .iter()
            .map(|root| root.store_path.as_path())
            .collect::<HashSet<_>>();
        let cached = self.get_all(&store_paths)?;
        eprintln!("Cached {}", cached.len());

        let mut result = Vec::with_capacity(store_paths.len());
        let mut uncached = HashMap::with_capacity(store_paths.len() - cached.len());

        // TODO: parallel
        let mut progress = 0;
        let total = store_paths.len();
        for root in roots.iter().cloned() {
            let path_info = match cached
                .get(root.store_path.as_path())
                .or_else(|| uncached.get(&root.store_path))
            {
                Some(path_info) => path_info.clone(),
                None => {
                    let path_info =
                        // TODO: batch
                        Rc::new(path_info(false, [&root.store_path]).with_context(|| {
                            format!(
                                "Failed to compute path-info for {:?} -> {:?}",
                                root.symlink, root.store_path
                            )
                        })?);
                    progress += 1;
                    eprintln!(
                        "path_info ({:?}) {}/{}",
                        root.store_path,
                        progress,
                        (total - cached.len())
                    );
                    uncached
                        .entry(root.store_path.clone())
                        .or_insert(path_info.clone())
                        .clone()
                }
            };
            result.push(GcRootWithPaths { root, path_info });
        }

        eprintln!("Uncached {}", uncached.len());
        self.put_all(uncached)?;

        Ok(result)
    }

    pub fn get_sizes(&self, roots: Vec<GcRoot>) -> Result<Vec<GcRootWithSize>> {
        let store_paths = roots.iter().map(|root| root.store_path.as_path()).collect();
        let cached = self.get_all(&store_paths)?;

        let mut uncached = HashMap::with_capacity(roots.len() - cached.len());
        let mut with_size = Vec::with_capacity(roots.len());
        for root in roots.iter().cloned() {
            let path = if let Some(cached) = cached.get(root.store_path.as_path()) {
                cached.get(&root.store_path)
            } else {
                let path_info = path_info(false, [&root.store_path]).with_context(|| {
                    format!(
                        "Failed to compute path-info for {:?} -> {:?}",
                        root.symlink, root.store_path
                    )
                })?;
                // Some(uncached.entry(root.store_path).or_insert(path_info))
                todo!()
            };

            with_size.push(GcRootWithSize {
                symlink: root.symlink,
                modified: root.modified,
                store_path: root.store_path,
                nar_size: path.map(|p| p.nar_size),
            });
        }

        self.put_all(uncached)?;

        Ok(with_size)
    }

    fn get(&self, txn: &heed::RoTxn<WithTls>, path: &Path) -> Result<Option<PathInfoMap>> {
        let data = self.db.get(txn, path.as_os_str().as_encoded_bytes())?;
        let Some(data) = data else {
            return Ok(None);
        };
        Ok(Some(deserialize(data)?))
    }

    fn get_all<'a>(&self, paths: &HashSet<&'a Path>) -> Result<HashMap<&'a Path, Rc<PathInfoMap>>> {
        let txn = self.env.read_txn().context("Failed to start read txn")?;
        let entries = paths
            .iter()
            .filter_map(|path| match self.get(&txn, path) {
                Ok(path_info) => Some((*path, Rc::new(path_info?))),
                Err(err) => {
                    eprintln!("Failed to load cached path info {path:?}: {err}");
                    None
                }
            })
            .collect::<HashMap<_, _>>();
        txn.commit().context("Failed to commit read txn")?;
        Ok(entries)
    }

    fn put_all(&self, paths: HashMap<PathBuf, Rc<PathInfoMap>>) -> Result<()> {
        let mut txn = self.env.write_txn().context("Failed to start write txn")?;
        let mut buf = Vec::with_capacity(8 * 1024);
        for (path, path_info) in paths {
            let value = serialize(path_info.as_ref(), &mut buf)
                .with_context(|| format!("Failed to serialize {path:?} to cache"))?;
            self.db
                .put(&mut txn, path.as_os_str().as_encoded_bytes(), value)
                .with_context(|| format!("Failed to write {path:?} to cache"))?;
        }
        txn.commit().context("Failed to commit write txn")?;
        Ok(())
    }
}

pub fn serialize<'b>(paths: &PathInfoMap, buf: &'b mut Vec<u8>) -> Result<&'b [u8]> {
    let cursor = Cursor::new(&mut *buf);
    let mut encoder = zstd::stream::write::Encoder::new(cursor, 0)?;
    serde_json::to_writer(&mut encoder, paths)?;
    let cursor = encoder.finish()?;
    let position = cursor.position() as usize;
    Ok(&buf[..position])
}

pub fn deserialize(buf: &[u8]) -> Result<PathInfoMap> {
    // let reader = zstd::stream::read::Decoder::new(buf)?;
    // Ok(serde_json::from_reader(reader)?)
    let buf = zstd::decode_all(buf)?;
    Ok(serde_json::from_slice(&buf)?)
}
