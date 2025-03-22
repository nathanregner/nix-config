# https://github.com/firefox-devtools/profiler/blob/main/docs-developer/loading-in-profiles.md#url
# usage: perf script -F +pid | perf2ff
{
  lib,
  mkShell,
  openssl,
  rustPlatform,
  ...
}:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "perf2ff";
    version = "0.1.0";

    src = lib.cleanSource ./.;
    cargoLock.lockFile = ./Cargo.lock;

    passthru.devShell = mkShell {
      RUST_SRC_PATH = "${rustPlatform.rustcSrc}/library";
      packages = pkg.nativeBuildInputs ++ pkg.buildInputs ++ [ openssl ];
    };
  };
in
pkg
