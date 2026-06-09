use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use petgraph::graph::NodeIndex;
use petgraph::visit::EdgeRef;
use tui_treelistview::TreeModel;

use crate::store_graph::DominatorGraph;

pub struct GcRootModel {
    pub graph: DominatorGraph,
    pub root_id: Option<NodeIndex>,
    pub show_profiles: bool,
    pub marked: Vec<bool>,
    children_cache: Vec<Vec<NodeIndex>>,
}

impl GcRootModel {
    pub fn new(graph: DominatorGraph) -> Self {
        let node_count = graph.node_count();

        let root_id = graph.node_indices().find(|&ni| {
            graph
                .node_weight(ni)
                .map(|d| d.path == Path::new("/"))
                .unwrap_or(false)
        });

        let mut children_cache: Vec<Vec<NodeIndex>> = vec![Vec::new(); node_count];
        for ni in graph.node_indices() {
            let children: Vec<NodeIndex> = graph.edges(ni).map(|e| e.target()).collect();
            children_cache[ni.index()] = children;
        }

        for children in &mut children_cache {
            children.sort_by(|a, b| {
                let path_a = graph.node_weight(*a).map(|d| &d.path);
                let path_b = graph.node_weight(*b).map(|d| &d.path);
                path_a.cmp(&path_b)
            });
        }

        Self {
            graph,
            root_id,
            show_profiles: false,
            marked: vec![false; node_count],
            children_cache,
        }
    }

    pub fn path(&self, id: NodeIndex) -> Option<&Path> {
        self.graph.node_weight(id).map(|d| d.path.as_path())
    }

    pub fn name(&self, id: NodeIndex) -> Option<&str> {
        self.graph
            .node_weight(id)
            .and_then(|d| d.path.file_name().map(|s| s.to_str().unwrap_or("")))
    }

    pub fn added_size(&self, id: NodeIndex) -> u64 {
        self.graph
            .node_weight(id)
            .map(|d| d.added_size)
            .unwrap_or(0)
    }

    #[allow(dead_code)]
    pub fn closure_size(&self, id: NodeIndex) -> u64 {
        self.graph
            .node_weight(id)
            .map(|d| d.closure_size)
            .unwrap_or(0)
    }

    pub fn is_marked(&self, id: NodeIndex) -> bool {
        self.marked.get(id.index()).copied().unwrap_or(false)
    }

    pub fn marked_count(&self) -> usize {
        self.get_marked_paths().len()
    }

    pub fn toggle_profiles(&mut self) {
        self.show_profiles = !self.show_profiles;
    }

    pub fn is_top_level(&self, id: NodeIndex) -> bool {
        Some(id) == self.root_id
    }

    pub fn toggle_mark(&mut self, id: NodeIndex) {
        if self.is_top_level(id) {
            return;
        }
        if let Some(marked) = self.marked.get_mut(id.index()) {
            *marked = !*marked;
        }
    }

    pub fn get_marked_paths(&self) -> Vec<&Path> {
        let mut paths = Vec::new();
        if let Some(root_id) = self.root_id {
            self.collect_marked_paths(root_id, false, &mut paths);
        }
        paths
    }

    fn collect_marked_paths<'a>(
        &'a self,
        id: NodeIndex,
        parent_marked: bool,
        paths: &mut Vec<&'a Path>,
    ) {
        let is_marked = self.is_marked(id) || parent_marked;
        let children = &self.children_cache[id.index()];

        if children.is_empty() {
            if is_marked {
                if let Some(path) = self.path(id) {
                    paths.push(path);
                }
            }
        } else {
            for &child in children {
                self.collect_marked_paths(child, is_marked, paths);
            }
        }
    }

    pub fn reset_marks(&mut self) {
        self.marked.fill(false);
    }

    #[allow(dead_code)]
    pub fn delete_marked(&mut self) -> Result<usize> {
        let marked: Vec<PathBuf> = self
            .get_marked_paths()
            .iter()
            .map(|p| p.to_path_buf())
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
    type Id = NodeIndex;

    fn root(&self) -> Option<Self::Id> {
        self.root_id
    }

    fn children(&self, id: Self::Id) -> &[Self::Id] {
        &self.children_cache[id.index()]
    }

    fn contains(&self, id: Self::Id) -> bool {
        self.graph.node_weight(id).is_some()
    }

    fn size_hint(&self) -> usize {
        self.graph.node_count()
    }
}

#[allow(dead_code)]
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

