use std::collections::HashMap;

use rkyv::{Archive, Deserialize, Serialize};

#[derive(Archive, Serialize, Deserialize, Debug)]
pub struct PathInfo {
    pub nar_size: u64,
    pub references: Vec<String>,
}

pub type PathInfoMap = HashMap<String, PathInfo>;
