# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{
  fenix,
  fetchurl,
  installShellFiles,
  lib,
  makeRustPlatform,
  mkShell,
  nvd,
  remarshal,
  runCommand,
  rust-analyzer,
  rustPlatform,
  rustfmt,
}:
let
  rustPlatform = makeRustPlatform rec {
    inherit (fenix.minimal) toolchain;
    rustc = toolchain;
    cargo = toolchain;
  };

  pkg = rustPlatform.buildRustPackage {
    pname = "openapi-tools";
    version = "0.0.1";

    # src = lib.sources.sourceFilesBySuffices (lib.cleanSource ./.) [ ".nix" ];
    src = lib.cleanSource ./.;

    nativeBuildInputs = [ installShellFiles ];

    postPatch = ''
      ln -sf ${./Cargo.toml} Cargo.toml
      ln -sf ${./Cargo.lock} Cargo.lock
    '';

    cargoLock.lockFile = ./Cargo.lock;

    cargoBuildFlags = [
      "-Z"
      "unstable-options"
      "--artifact-dir"
      "completions"
    ];

    postInstall = ''
      installShellCompletion target/completions/*
    '';

    passthru.devShell = mkShell {
      RUST_SRC_PATH = "${fenix.complete.rust-src}/lib/rustlib/src/rust/library";

      SWAGGER_PETSTORE = runCommand "swagger-petstore.json" { nativeBuildInputs = [ remarshal ]; } ''
        remarshal ${
          fetchurl {
            url = "https://raw.githubusercontent.com/swagger-api/swagger-petstore/a0f12dd24efcf2fd68faa59c371ea5e35a90bbd1/src/main/resources/openapi.yaml";
            sha256 = "sha256-n9dTzphU0HbFhKSRKvngqEntjxXVcslNVFydTaqIvJI=";
          }
        } -of json -o $out --json-indent 2
      '';

      packages = [
        (fenix.complete.withComponents [
          "cargo"
          "clippy"
          "rust-analyzer"
          "rust-src"
          "rustfmt"
        ])
      ];
    };
  };
in
pkg
