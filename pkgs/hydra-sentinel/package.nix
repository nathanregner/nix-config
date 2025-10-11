{
  lib,
  cargo-update-script,
  libappindicator,
  libayatana-appindicator,
  mkRustShell,
  openssl,
  pkg-config,
  rustPlatform,
  stdenv,
  xcbuild,
  xdotool,
}:
let
  pkg = rustPlatform.buildRustPackage {
    pname = "hydra-sentinel";
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

    nativeBuildInputs = [
      pkg-config
      xcbuild
      # rustPlatform.bindgenHook
    ];
    buildInputs = [
      openssl.dev
    ]
    ++ (lib.optionals stdenv.isLinux [
      libappindicator.dev
      libayatana-appindicator.dev
      xdotool
    ]);

    passthru = {
      updateScript = cargo-update-script pkg { breaking = false; };
      devShell = mkRustShell {
        inherit pkg rustPlatform;
      };
    };
  };
in
pkg
