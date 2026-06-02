use std::{
    collections::HashMap,
    path::{Path, PathBuf},
};

#[derive(Default)]
pub struct Trie<V> {
    prefix: PathBuf,
    entry: Option<Entry<V>>,
    children: HashMap<PathBuf, Trie<V>>,
}

impl<V> Trie<V> {
    pub fn insert(&mut self, key: &Path, value: V) {}

    fn insert_with(&mut self, prefix: &Path, key: &Path, value: V) {
        if self.children.is_empty() {
            self.entry = Some(Entry {
                key: key.to_owned(),
                value,
            });
        }
    }
}

struct Entry<V> {
    key: PathBuf,
    value: V,
}
