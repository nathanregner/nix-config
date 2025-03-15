# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{
  lib,
  cargo,
  clippy,
  fetchurl,
  installShellFiles,
  makeRustPlatform,
  mkRustShell,
  nvd,
  remarshal,
  runCommand,
  rust-analyzer,
  rustPlatform,
  rustfmt,
  ...
}:
let
  env = {
    RUSTC_BOOTSTRAP = true;
  };

  pkg = rustPlatform.buildRustPackage {
    pname = "openapi-tools";
    version = "0.0.1";
    src = lib.cleanSource ./.;

    cargoLock.lockFile = ./Cargo.lock;

    inherit env;

    nativeBuildInputs = [ installShellFiles ];

    cargoBuildFlags = [
      "-Z"
      "unstable-options"
      "--artifact-dir"
      "completions"
    ];

    postInstall = ''
      installShellCompletion target/completions/*
    '';

    passthru.devShell = mkRustShell {
      inherit env pkg rustPlatform;

      SWAGGER_PETSTORE = runCommand "swagger-petstore.json" { nativeBuildInputs = [ remarshal ]; } ''
        remarshal ${
          fetchurl {
            url = "https://raw.githubusercontent.com/swagger-api/swagger-petstore/a0f12dd24efcf2fd68faa59c371ea5e35a90bbd1/src/main/resources/openapi.yaml";
            sha256 = "sha256-n9dTzphU0HbFhKSRKvngqEntjxXVcslNVFydTaqIvJI=";
          }
        } -of json -o $out --json-indent 2
      '';
    };
  };
in
pkg
