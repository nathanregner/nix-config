{
  fetchFromGitHub,
  nix-update-script,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "harper-ls";
  version = "0.20.0";
  src = fetchFromGitHub {
    owner = "elijah-potter";
    repo = "harper";
    rev = "v0.19.1";
    sha256 = "sha256-3W/pFtI8G9GOEXt1nCpoy+vp6+59Ya3oqlx2EttGEIk=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  passthru.updateScript = nix-update-script { };
}
