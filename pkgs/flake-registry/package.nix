{
  lib,
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "flake-registry";
  version = "0-unstable-2025-11-19";
  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "flake-registry";
    rev = "cb70c9306b44501de412649c356dee503a25f119";
    fetchSubmodules = false;
    sha256 = "sha256-q2jzJQdsJMpD3dbuNphQJgwx6XeGPonWOp43U0nY7o0=";
  };
  installPhase = ''
    mv flake-registry.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta.platforms = lib.platforms.unix;
}
