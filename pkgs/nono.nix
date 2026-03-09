{
  lib,
  fetchFromGitHub,
  nix-update-script,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "nono";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "always-further";
    repo = "nono";
    tag = "v${version}";
    hash = "sha256-d0YzjKhE9cSHQ9XRKN4CaUuShYTjQOP+NoEhGmMcx1Y=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  cargoBuildFlags = [
    "--package"
    "nono-cli"
  ];
  cargoTestFlags = [
    "--package"
    "nono-cli"
  ];

  # Test env_nono_allow_comma_separated fails in sandbox
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "AI agent security sandbox using Landlock/seccomp (Linux) and Seatbelt (macOS)";
    homepage = "https://github.com/always-further/nono";
    license = lib.licenses.asl20;
    mainProgram = "nono";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
