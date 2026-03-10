use clap::CommandFactory;
use clap_complete::aot::Bash;
use clap_complete::{generate_to, shells::Zsh};
use std::io::Error;

include!("src/cli.rs");

fn main() -> Result<(), Error> {
    let outdir = "target/completions";
    let _ = std::fs::remove_dir_all(outdir);
    std::fs::create_dir_all(outdir)?;

    let mut cmd = <Cli as CommandFactory>::command();
    generate_to(Bash, &mut cmd, "tmux-agent-status", outdir)?;
    generate_to(Zsh, &mut cmd, "tmux-agent-status", outdir)?;

    Ok(())
}
