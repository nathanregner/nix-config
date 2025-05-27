# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{
  lib,
  cargo-update-script,
  installShellFiles,
  mkRustShell,
  nvd,
  rustPlatform,
}:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "hydra-auto-upgrade";
    version = "1.0.0";

    src = lib.cleanSource ./.;
    cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = [ installShellFiles ];

    runtimeInputs = [ nvd ];

    cargoBuildFlags = [
      "-Z"
      "unstable-options"
      "--artifact-dir"
      "completions"
    ];

    postConfigure = ''
      substituteInPlace src/main.rs \
        --replace-fail '"nvd"' '"${lib.getExe nvd}"'
    '';

    postInstall = ''
      installShellCompletion target/completions/*
    '';

    passthru = {
      updateScript = cargo-update-script pkg { };
      devShell = mkRustShell {
        inherit pkg rustPlatform;
      };
    };
  };
in
pkg
