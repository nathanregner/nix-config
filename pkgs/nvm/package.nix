{
  fetchFromGitHub,
  stdenv,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "nvm";
  version = "v0.39.7";
  src = fetchFromGitHub {
    owner = "nvm-sh";
    repo = "nvm";
    rev = "v0.39.7";
    fetchSubmodules = false;
    sha256 = "sha256-wtLDyLTF3eOae2htEjfFtx/54Vudsvdq65Zp/IsYTX8=";
  };

  passthru.updateScript = nix-update-script;
}
