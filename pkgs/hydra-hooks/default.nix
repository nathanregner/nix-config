# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{ lib, rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "hydra-hooks";
  version = "1.0.0";

  # src = lib.sources.sourceFilesBySuffices (lib.cleanSource ./.) [ ".nix" ];
  src = lib.cleanSource ./.;

  postPatch = ''
    ln -sf ${./Cargo.toml} Cargo.toml
    ln -sf ${./Cargo.lock} Cargo.lock
  '';

  cargoLock.lockFile = ./Cargo.lock;
}

