use std::{
    collections::{BTreeMap, HashMap},
    ffi::OsStr,
    ops::ControlFlow,
    path::{Path, PathBuf},
};

pub mod cache;
pub mod nix;
pub mod types;

#[derive(Debug)]
struct PathRadixTree<V> {
    entry: Option<Entry<V>>,
    children: BTreeMap<PathBuf, PathRadixTree<V>>,
}

impl<V> Default for PathRadixTree<V> {
    fn default() -> Self {
        Self {
            entry: Default::default(),
            children: Default::default(),
        }
    }
}

#[derive(Debug)]
struct Entry<V> {
    path: PathBuf,
    value: V,
}

impl<V> PathRadixTree<V> {
    pub fn insert(&mut self, path: impl Into<PathBuf>, value: V) {
        let path = path.into();
        self.insert_rec(PathBuf::new(), path.clone(), Entry { path, value });
    }

    fn insert_rec(
        &mut self,
        edge: PathBuf,
        key: PathBuf,
        mut entry: Entry<V>,
    ) -> ControlFlow<(), Entry<V>> {
        // TODO: remove clone
        if let Some((edge, next)) = self.children.range_mut(key.clone()..).next() {
            entry = next.split(edge, &key, entry)?;
        };
        if let Some((edge, next)) = self.children.range_mut(..=key.clone()).next() {
            entry = next.split(edge, &key, entry)?;
        };

        entry = self.split(&key, &key, entry)?;
        ControlFlow::Break(())
    }

    fn split(&mut self, edge: &PathBuf, key: &Path, entry: Entry<V>) -> ControlFlow<(), Entry<V>> {
        let Some((common, existing, new)) = split_prefix(edge, key) else {
            return ControlFlow::Continue(entry);
        };
        if &common == edge {
            return self.insert_rec(common, new, entry);
        }

        let Some(child) = self.children.remove(edge) else {
            if self
                .entry
                .as_ref()
                .map(|existing| existing.path == entry.path)
                .unwrap_or_default()
                || self.children.is_empty()
            {
                self.entry = Some(entry);
            }

            return ControlFlow::Break(());
        };

        let mut split = Self::default();
        split.children.insert(existing, child);
        split.children.insert(new, Self::default());
        self.children.insert(common, split);

        ControlFlow::Break(())
    }
}

fn split_prefix(a: &Path, b: &Path) -> Option<(PathBuf, PathBuf, PathBuf)> {
    let mut prefix = PathBuf::new();
    let (mut a_components, mut a_remainder) = (a.components().peekable(), PathBuf::new());
    let (mut b_components, mut b_remainder) = (b.components().peekable(), PathBuf::new());

    while let (Some(a), Some(b)) = (a_components.peek(), b_components.peek())
        && a == b
    {
        prefix = prefix.join(a);
        a_components.next();
        b_components.next();
    }

    if prefix == PathBuf::default() {
        return None;
    }

    a_remainder.extend(a_components);
    b_remainder.extend(b_components);

    // add trailing slash
    prefix.push("");
    a_remainder.push("");
    b_remainder.push("");

    Some((prefix, a_remainder, b_remainder))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn assert_split_prefix(a: &Path, b: &Path, expected: Option<(&str, &str, &str)>) {
        let actual = split_prefix(a, b).map(|(prefix, a, b)| {
            (
                prefix.as_os_str().to_string_lossy().into(),
                a.as_os_str().to_string_lossy().into(),
                b.as_os_str().to_string_lossy().into(),
            )
        });
        let expected =
            expected.map(|(prefix, a, b)| (prefix.to_string(), a.to_string(), b.to_string()));
        assert_eq!(actual, expected);
    }

    #[test]
    fn split_prefix_root() {
        assert_split_prefix(
            Path::new("/a/b/c/"),
            Path::new("/b/c"),
            Some(("/", "a/b/c/", "b/c/")),
        );
    }

    #[test]
    fn split_prefix_multiple() {
        assert_split_prefix(
            Path::new("/nix/store/a"),
            Path::new("/nix/store/b"),
            Some(("/nix/store/", "a/", "b/")),
        );
    }

    #[test]
    fn split_prefix_none() {
        assert_split_prefix(Path::new("a/b/c/"), Path::new("b/c"), None);
    }

    #[test]
    fn insert() {
        let mut tree = PathRadixTree::default();
        tree.insert("/", 1);
        tree.insert("/", 2);
        tree.insert("/", 3);

        dbg!(tree);
    }
}
