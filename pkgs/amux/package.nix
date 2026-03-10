{
  lib,
  cargo-insta,
  cargo-update-script,
  installShellFiles,
  mkRustShell,
  rustPlatform,
  tmux,
}:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "amux";
    version = "0.1.0";

    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./Cargo.lock
        ./Cargo.toml
        ./build.rs
        ./src
        ./tests
      ];
    };

    nativeBuildInputs = [
      installShellFiles
      rustPlatform.cargoCheckHook
      tmux
    ];

    cargoBuildFlags = [
      "-Z"
      "unstable-options"
      "--artifact-dir"
      "completions"
    ];

    postInstall = ''
      installShellCompletion target/completions/*
    '';

    cargoLock.lockFile = ./Cargo.lock;

    passthru = {
      updateScript = cargo-update-script pkg { breaking = false; };
      devShell = mkRustShell {
        inherit pkg rustPlatform;
        packages = [ cargo-insta ];
      };
    };
  };
in
pkg
