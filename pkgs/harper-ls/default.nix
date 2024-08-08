# TODO: upstream
{ rustPlatform, fetchFromGitHub }:
rustPlatform.buildRustPackage rec {
  pname = "harper-ls";
  version = "0.9.2";

  src = fetchFromGitHub {
    owner = "elijah-potter";
    repo = "harper";
    rev = "v${version}";
    sha256 = "sha256-XfyEp3PLLWq7yDV8UcMfJRyP39scuw94jwhGxuMz958=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";
}
