{
  fetchFromGitHub,
  nix-update-script,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "harper-ls";
  version = "0.21.1";
  src = fetchFromGitHub {
    owner = "elijah-potter";
    repo = "harper";
    rev = "v${version}";
    sha256 = "sha256-3W/pFtI8G9GOEXt1nCpoy+vp6+59Ya3oqlx2EttGEIk=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  passthru.updateScript = nix-update-script { };
}
