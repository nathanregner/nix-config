{
  lib,
  cargo-insta,
  cargo-update-script,
  mkRustShell,
  rustPlatform,
}:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "nix-gc-roots";
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

    passthru = {
      updateScript = cargo-update-script pkg { breaking = false; };
      devShell = mkRustShell {
        inherit pkg rustPlatform;
        env.CARGO_PROFILE_RELEASE_DEBUG = true;
        packages = [ cargo-insta ];
      };
    };
  };
in
pkg
