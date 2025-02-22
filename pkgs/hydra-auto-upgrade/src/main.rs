mod cli;
mod hydra;

use clap::Parser;
use cli::Profile;
use core::error::Error;
use hydra::Build;
use std::{
    fs,
    io::{self},
    path::Path,
    process::Command,
};
use tempdir::TempDir;

type Result<T> = std::result::Result<T, Box<dyn Error>>;

fn main() -> Result<()> {
    let args = cli::Args::parse();
    let profile = args.profile;
    let profile_path = profile.path();

    let build = hydra::get_latest_build(&args)?;

    if fs::canonicalize(profile.path())? == build.out_path() {
        if args.force {
            eprintln!("Profile unchanged, skipping activation");
            return Ok(());
        }
        eprintln!("Re-running activation script");
    } else {
        copy(&build)?;
        diff(&profile_path, &build)?;
        eprintln!();
    };

    activate(profile, &build, &args.activate_args)?;

    Ok(())
}

fn copy(build: &Build) -> io::Result<()> {
    let mut command = Command::new("nix");
    command.arg("build").arg("--no-link").arg(&build.out_path());
    exec(&mut command)
}

fn diff(profile_path: &Path, build: &Build) -> io::Result<()> {
    let mut command = Command::new("nvd");
    command
        .arg("--color=always")
        .arg("diff")
        .arg(profile_path)
        .arg(build.out_path());
    exec(&mut command)
}

fn activate(profile: Profile, build: &Build, args: &[String]) -> io::Result<()> {
    let tempdir = TempDir::new("activate")?;

    let activate_rs = build.out_path().join("activate-rs");
    let mut command = if atty::is(atty::Stream::Stdout) && profile == Profile::System {
        let mut command = Command::new("sudo");
        command.arg(activate_rs);
        command
    } else {
        Command::new(activate_rs)
    };
    command.arg("activate");
    command.arg(build.out_path());
    command.arg("--temp-path");
    command.arg(tempdir.path());

    command.args(["--confirm-timeout", "60"]);

    match profile {
        Profile::Home { .. } => {
            command.args(["--profile-user", &whoami::username()]);
            command.args(["--profile-name", "home-manager"]);
        }
        Profile::System { .. } => {
            command.args(["--profile-user", "root"]);
            command.args(["--profile-name", "system"]);
        }
    };

    command.args(args);

    exec(&mut command)?;

    drop(tempdir);
    Ok(())
}

fn exec(command: &mut Command) -> io::Result<()> {
    eprintln!("{command:?}");
    command.spawn()?.wait()?;
    Ok(())
}
