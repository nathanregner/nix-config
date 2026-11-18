{
  lib,
  aws-lc,
  cargo-update-script,
  mkRustShell,
  pkg-config,
  rustPlatform,
  stdenv,
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

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      pkg-config
    ];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      aws-lc
    ];

    passthru = {
      updateScript = cargo-update-script pkg { breaking = false; };
      devShell = mkRustShell {
        inherit pkg rustPlatform;
      };
    };
  };
in
pkg
