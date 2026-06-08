use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

use anyhow::{Context, Result};
use tui_treelistview::TreeModel;

use crate::cache::GcRootWithSize;

#[derive(Clone)]
pub struct GcRootEntry {
    pub path: PathBuf,
    pub target: PathBuf,
    pub modified: SystemTime,
    pub is_profile: bool,
    pub closure_size: Option<u64>,
}

impl From<GcRootWithSize> for GcRootEntry {
    fn from(root: GcRootWithSize) -> Self {
        let is_profile = is_profile_path(&root.symlink);
        Self {
            path: root.symlink,
            target: root.store_path,
            modified: root.modified,
            is_profile,
            closure_size: root.nar_size,
        }
    }
}

pub enum Node {
    Directory {
        name: String,
        path: PathBuf,
        parent: Option<usize>,
        all_children: Vec<usize>,
        visible_children: Vec<usize>,
        marked: bool,
    },
    Root {
        root: GcRootEntry,
        marked: bool,
    },
}

pub struct GcRootModel {
    pub nodes: Vec<Node>,
    pub root_id: Option<usize>,
    pub show_profiles: bool,
}

impl GcRootModel {
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            root_id: None,
            show_profiles: false,
        }
    }

    pub fn marked_count(&self) -> usize {
        self.get_marked_roots().len()
    }

    pub fn build_from_roots(roots: Vec<GcRootWithSize>) -> Self {
        let entries: Vec<GcRootEntry> = roots.into_iter().map(GcRootEntry::from).collect();
        Self::build_from_entries(entries)
    }

    pub fn build_from_entries(mut entries: Vec<GcRootEntry>) -> Self {
        let mut model = Self::new();
        if entries.is_empty() {
            return model;
        }

        entries.sort_by(|a, b| a.path.cmp(&b.path));

        let mut dir_map: HashMap<PathBuf, usize> = HashMap::new();

        let virtual_root_id = model.nodes.len();
        model.nodes.push(Node::Directory {
            name: String::new(),
            path: PathBuf::new(),
            parent: None,
            all_children: Vec::new(),
            visible_children: Vec::new(),
            marked: false,
        });
        model.root_id = Some(virtual_root_id);

        for entry in entries {
            let parent_path = entry.path.parent().unwrap_or(&entry.path).to_path_buf();

            let parent_id =
                model.ensure_directory_chain(&mut dir_map, &parent_path, virtual_root_id);

            let root_id = model.nodes.len();
            model.nodes.push(Node::Root {
                root: entry,
                marked: false,
            });

            if let Node::Directory { all_children, .. } = &mut model.nodes[parent_id] {
                all_children.push(root_id);
            }
        }

        model.update_visibility();
        model
    }

    fn ensure_directory_chain(
        &mut self,
        dir_map: &mut HashMap<PathBuf, usize>,
        path: &PathBuf,
        virtual_root_id: usize,
    ) -> usize {
        if let Some(&id) = dir_map.get(path) {
            return id;
        }

        let parent_id = if let Some(parent_path) = path.parent() {
            if parent_path == path || parent_path.as_os_str().is_empty() {
                virtual_root_id
            } else {
                self.ensure_directory_chain(dir_map, &parent_path.to_path_buf(), virtual_root_id)
            }
        } else {
            virtual_root_id
        };

        let dir_id = self.nodes.len();
        let name = path
            .file_name()
            .map(|s| s.to_string_lossy().to_string())
            .unwrap_or_else(|| path.to_string_lossy().to_string());

        self.nodes.push(Node::Directory {
            name,
            path: path.clone(),
            parent: Some(parent_id),
            all_children: Vec::new(),
            visible_children: Vec::new(),
            marked: false,
        });

        if let Node::Directory { all_children, .. } = &mut self.nodes[parent_id] {
            all_children.push(dir_id);
        }

        dir_map.insert(path.clone(), dir_id);
        dir_id
    }

    fn is_node_visible(&self, id: usize) -> bool {
        match &self.nodes[id] {
            Node::Directory { .. } => true,
            Node::Root { root, .. } => self.show_profiles || !root.is_profile,
        }
    }

    fn has_visible_descendants(&self, id: usize) -> bool {
        match &self.nodes[id] {
            Node::Root { .. } => self.is_node_visible(id),
            Node::Directory { all_children, .. } => all_children
                .iter()
                .any(|&child_id| self.has_visible_descendants(child_id)),
        }
    }

    pub fn update_visibility(&mut self) {
        let len = self.nodes.len();
        for id in 0..len {
            if let Node::Directory { all_children, .. } = &self.nodes[id] {
                let children_copy: Vec<usize> = all_children.clone();
                let visible: Vec<usize> = children_copy
                    .into_iter()
                    .filter(|&child_id| self.has_visible_descendants(child_id))
                    .collect();

                if let Node::Directory {
                    visible_children, ..
                } = &mut self.nodes[id]
                {
                    *visible_children = visible;
                }
            }
        }
    }

    pub fn toggle_profiles(&mut self) {
        self.show_profiles = !self.show_profiles;
        self.update_visibility();
    }

    pub fn is_top_level(&self, id: usize) -> bool {
        if Some(id) == self.root_id {
            return true;
        }
        if let Node::Directory { parent, .. } = &self.nodes[id] {
            return *parent == self.root_id;
        }
        false
    }

    pub fn toggle_mark(&mut self, id: usize) {
        if self.is_top_level(id) {
            return;
        }

        match &mut self.nodes[id] {
            Node::Root { marked, .. } | Node::Directory { marked, .. } => {
                *marked = !*marked;
            }
        }
    }

    pub fn get_marked_roots(&self) -> Vec<&GcRootEntry> {
        let mut roots = Vec::new();
        if let Some(root_id) = self.root_id {
            self.collect_marked_roots(root_id, false, &mut roots);
        }
        roots
    }

    fn collect_marked_roots<'a>(
        &'a self,
        id: usize,
        parent_marked: bool,
        roots: &mut Vec<&'a GcRootEntry>,
    ) {
        match &self.nodes[id] {
            Node::Root { root, marked } => {
                if *marked || parent_marked {
                    roots.push(root);
                }
            }
            Node::Directory {
                all_children,
                marked,
                ..
            } => {
                let is_marked = *marked || parent_marked;
                for &child in all_children {
                    self.collect_marked_roots(child, is_marked, roots);
                }
            }
        }
    }

    pub fn reset_marks(&mut self) {
        for node in &mut self.nodes {
            match node {
                Node::Directory { marked, .. } | Node::Root { marked, .. } => {
                    *marked = false;
                }
            }
        }
    }

    pub fn delete_marked(&mut self) -> Result<usize> {
        let marked: Vec<PathBuf> = self
            .get_marked_roots()
            .iter()
            .map(|r| r.path.clone())
            .collect();
        let count = marked.len();

        for path in &marked {
            std::fs::remove_file(path)
                .with_context(|| format!("Failed to delete {}", path.display()))?;
        }

        Ok(count)
    }
}

impl TreeModel for GcRootModel {
    type Id = usize;

    fn root(&self) -> Option<Self::Id> {
        self.root_id
    }

    fn children(&self, id: Self::Id) -> &[Self::Id] {
        match &self.nodes[id] {
            Node::Directory {
                visible_children, ..
            } => visible_children,
            Node::Root { .. } => &[],
        }
    }

    fn contains(&self, id: Self::Id) -> bool {
        id < self.nodes.len()
    }

    fn size_hint(&self) -> usize {
        self.nodes.len()
    }
}

pub fn is_profile_path(path: &Path) -> bool {
    let path_str = path.to_string_lossy();
    path_str.contains("/nix/var/nix/profiles/")
        || path_str.contains("/.local/state/nix/profiles/")
        || path_str.contains("/run/") && path_str.contains("-system")
}

pub fn is_direnv_path(path: &Path) -> bool {
    path.components().any(|c| c.as_os_str() == ".direnv")
}

pub fn format_size(bytes: u64) -> String {
    const UNITS: [&str; 5] = ["B", "K", "M", "G", "T"];
    let mut value = bytes as f64;
    let mut unit = 0;
    while value >= 1024.0 && unit + 1 < UNITS.len() {
        value /= 1024.0;
        unit += 1;
    }
    if unit == 0 {
        format!("{:.0}{}", value, UNITS[unit])
    } else {
        format!("{:.1}{}", value, UNITS[unit])
    }
}

#[cfg(test)]
mod tests {
    use radix_trees::ptree::PTreeMap;
    use radix_trie::{Trie, TrieCommon};

    #[test]
    fn trie_old() {
        let mut trie = Trie::new();
        trie.insert("/nix/store/test", 1234);
        trie.insert("/home/nregner/file.txt", 1234);
        trie.insert("/home/nregner/file2.txt", 1234);

        dbg!(&trie.get("/"));
        // dbg!(&trie.get("/nix/store/test"));
        for t in TrieCommon::children(&trie) {
            eprintln!("{:?}", t.prefix());
            for c in t.children() {
                eprintln!("  {:?}", c.key());
                for c in c.children() {
                    eprintln!("    {:?}", c.key());
                }
            }
        }
    }

    #[test]
    fn ptree() {
        let mut trie = PTreeMap::new();
        trie.insert("/nix/store/test", 1234);
        trie.insert("/home/nregner/file.txt", 1234);
        trie.insert("/home/nregner/file2.txt", 1234);

        dbg!(&trie.get("/home/nregner/"));
        // dbg!(&trie.get("/nix/store/test"));
        for (k, v) in trie.iter() {
            eprintln!("{:?} {:?}", &k.key().as_bytes()[0..k.masklen() as usize], v);
            // for c in t.children() {
            //     eprintln!("  {:?}", c.key());
            //     for c in c.children() {
            //         eprintln!("    {:?}", c.key());
            //     }
            // }
        }
    }
}
