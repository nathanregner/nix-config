# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{
  installShellFiles,
  lib,
  mkShell,
  nvd,
  rust-analyzer,
  rustPlatform,
  rustfmt,
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

    passthru.devShell = mkShell {
      RUST_SRC_PATH = "${rustPlatform.rustcSrc}/library";
      packages =
        pkg.nativeBuildInputs
        ++ pkg.buildInputs
        ++ [
          rust-analyzer
          rustfmt
        ];
    };
  };
in
pkg
