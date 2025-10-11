{
  lib,
  cargo-update-script,
  gtk3,
  libGL,
  libappindicator,
  libayatana-appindicator,
  libxkbcommon,
  mkRustShell,
  openssl,
  pkg-config,
  rustPlatform,
  stdenv,
  wayland,
  xcbuild,
  xdotool,
}:
let
  libs = [
    libGL
    libxkbcommon
    wayland
    libappindicator
    libayatana-appindicator
  ];
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
    ++ lib.optionals stdenv.isLinux (
      [
        gtk3.dev
        xdotool
      ]
      ++ libs
    );

    passthru = {
      updateScript = cargo-update-script pkg { breaking = false; };
      devShell = mkRustShell {
        inherit pkg rustPlatform;
        env.LD_LIBRARY_PATH = lib.optionalString stdenv.isLinux (lib.makeLibraryPath libs);
      };
    };
  };
in
pkg
