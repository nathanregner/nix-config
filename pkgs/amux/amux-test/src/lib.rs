use etcetera::BaseStrategy;
use std::path::{Path, PathBuf};

pub struct TestDirs(PathBuf);

impl TestDirs {
    pub fn new(path: &Path) -> Self {
        Self(path.to_path_buf())
    }

    pub fn temp() -> (tempfile::TempDir, Self) {
        let dir = tempfile::tempdir().unwrap();
        let test_dirs = Self::new(dir.path());
        (dir, test_dirs)
    }
}

impl BaseStrategy for TestDirs {
    fn home_dir(&self) -> &Path {
        &self.0
    }
    fn config_dir(&self) -> PathBuf {
        self.0.join("config")
    }
    fn data_dir(&self) -> PathBuf {
        self.0.join("data")
    }
    fn cache_dir(&self) -> PathBuf {
        self.0.join("cache")
    }
    fn state_dir(&self) -> Option<PathBuf> {
        Some(self.0.join("state"))
    }
    fn runtime_dir(&self) -> Option<PathBuf> {
        Some(self.0.join("runtime"))
    }
}
