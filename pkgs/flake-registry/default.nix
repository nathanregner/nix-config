{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "flake-registry";
  version = "0-unstable-2024-12-17";
  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "flake-registry";
    rev = "02fe640c9e117dd9d6a34efc7bcb8bd09c08111d";
    fetchSubmodules = false;
    sha256 = "sha256-/3gigrEBFORQs6a8LL5twoHs7biu08y/8Xc5aQmk3b0=";
  };
  installPhase = ''
    mv flake-registry.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
