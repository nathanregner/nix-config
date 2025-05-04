use clap::CommandFactory;
use clap_complete::aot::Bash;
use clap_complete::{generate_to, shells::Zsh};
use std::io::Error;

include!("src/cli.rs");

fn main() -> Result<(), Error> {
    let outdir = "target/completions";
    let _ = std::fs::remove_dir_all(outdir);
    std::fs::create_dir_all(outdir)?;

    let mut cmd = <crate::Args as CommandFactory>::command();
    generate_to(Bash, &mut cmd, "hydra-auto-upgrade", outdir)?;
    generate_to(Zsh, &mut cmd, "hydra-auto-upgrade", outdir)?;

    Ok(())
}
