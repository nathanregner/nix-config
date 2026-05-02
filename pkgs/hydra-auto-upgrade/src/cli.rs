use clap::{Parser, ValueEnum};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command()]
pub struct Args {
    pub profile: Profile,

    #[arg(long, default_value = "http://sagittarius:3001")]
    pub instance: String,
    #[arg(long, default_value = "nix-config")]
    pub project: String,
    #[arg(long, default_value = "master")]
    pub jobset: String,
    #[arg(long)]
    pub job: Option<String>,

    #[arg(long, default_value = "false")]
    pub force: bool,

    pub activate_args: Vec<String>,
}

#[derive(ValueEnum, Eq, PartialEq, Clone, Copy, Debug)]
pub enum Profile {
    Home,
    System,
}

impl Profile {
    pub fn path(&self) -> PathBuf {
        match self {
            Profile::Home { .. } => {
                #[allow(deprecated)] // never going to run on Windows
                let home = std::env::home_dir().expect("Failed to locate user $HOME");
                home.join(".local/state/nix/profiles/home-manager")
            }
            Profile::System { .. } => PathBuf::from("/run/current-system"),
        }
    }
}
