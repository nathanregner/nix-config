#[allow(dead_code)]
pub mod gitea {
    include!(concat!(env!("OUT_DIR"), "/gitea.rs"));
}

#[allow(dead_code)]
pub mod github {
    include!(concat!(env!("OUT_DIR"), "/github.rs"));
}
