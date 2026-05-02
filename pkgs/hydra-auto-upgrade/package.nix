# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{
  lib,
  cargo-update-script,
  dix,
  installShellFiles,
  makeWrapper,
  mkRustShell,
  rustPlatform,
}:
let
  runtimePath = lib.makeBinPath [
    dix
  ];
  pkg = rustPlatform.buildRustPackage {
    pname = "hydra-auto-upgrade";
    version = "1.0.0";

    src = lib.cleanSource ./.;
    cargoLock.lockFile = ./Cargo.lock;

    nativeBuildInputs = [
      installShellFiles
      makeWrapper
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

    postFixup = ''
      wrapProgram $out/bin/hydra-auto-upgrade --prefix PATH : "${runtimePath}"
    '';

    passthru = {
      updateScript = cargo-update-script pkg { breaking = false; };
      devShell = mkRustShell {
        inherit pkg rustPlatform;
      };
    };
  };
in
pkg
