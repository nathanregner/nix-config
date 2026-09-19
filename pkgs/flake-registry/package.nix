{
  lib,
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "flake-registry";
  version = "0-unstable-2026-09-14";
  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "flake-registry";
    rev = "46ea0f17cf6777e156a2be6ae802d9f95d93dd5e";
    fetchSubmodules = false;
    sha256 = "sha256-qhIiRTjzwr65WpepkXWGmA4Wwl/PD/gfr3mQqeYORBY=";
  };
  installPhase = ''
    mv flake-registry.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta.platforms = lib.platforms.unix;
}
