{
  lib,
  dbus,
  fetchFromGitHub,
  mkRustShell,
  nix-update-script,
  pkg-config,
  rustPlatform,
}:
let
  pkg = rustPlatform.buildRustPackage rec {
    pname = "nono";
    version = "0.16.0";

    src = fetchFromGitHub {
      owner = "always-further";
      repo = "nono";
      tag = "v${version}";
      hash = "sha256-spNRaC9QE+GvHYN9ja0n0HotRKf9O8OeCp3LMVc0P2I=";
    };

    patches = [
      ./0001-fix-remove-run-from-allowlist.patch
    ];

    cargoLock.lockFile = "${src}/Cargo.lock";

    nativeBuildInputs = [
      pkg-config
      rustPlatform.bindgenHook
    ];

    buildInputs = [
      dbus.dev
    ];

    # env_nono_allow_comma_separated fails in sandbox
    doCheck = false;

    passthru.updateScript = nix-update-script { };

    passthru.devShell = mkRustShell {
      inherit pkg rustPlatform;
    };

    meta = {
      description = "AI agent security sandbox using Landlock/seccomp (Linux) and Seatbelt (macOS)";
      homepage = "https://github.com/always-further/nono";
      license = lib.licenses.asl20;
      mainProgram = "nono";
      platforms = lib.platforms.linux ++ lib.platforms.darwin;
    };
  };
in
pkg
