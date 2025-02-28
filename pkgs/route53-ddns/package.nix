# https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md
{
  lib,
  rustPlatform,
  cmake,
  mkShell,
}:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "route53-ddns";
    version = "1.0.0";

    nativeBuildInputs = [ cmake ];

    src = lib.cleanSource ./.;
    cargoLock.lockFile = ./Cargo.lock;

    passthru.devShell = mkShell {
      RUST_SRC_PATH = "${rustPlatform.rustcSrc}/library";
      packages = pkg.nativeBuildInputs ++ pkg.buildInputs;
    };
  };
in
pkg
