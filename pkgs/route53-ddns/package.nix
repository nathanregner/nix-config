{
  lib,
  cmake,
  mkRustShell,
  rustPlatform,
  ...
}:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "route53-ddns";
    version = "1.0.0";

    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./Cargo.lock
        ./Cargo.toml
        ./src
      ];
    };

    cargoLock.lockFile = ./Cargo.lock;

    passthru.devShell = mkRustShell {
      inherit pkg rustPlatform;
    };
  };
in
pkg
