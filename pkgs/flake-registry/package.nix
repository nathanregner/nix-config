{
  lib,
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "flake-registry";
  version = "0-unstable-2026-06-27";
  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "flake-registry";
    rev = "10bd3d9e8eefb4725e346eddd3a505aa0aacf01b";
    fetchSubmodules = false;
    sha256 = "sha256-Jjp/ZivVqZCLptwlSuwU8n0a8b8PXJqabxpSG7KRNuI=";
  };
  installPhase = ''
    mv flake-registry.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta.platforms = lib.platforms.unix;
}
