{
  stdenv,
  lib,
  fetchFromGitHub,
  nodejs,
  buildNpmPackage,
  nix-update-script,
}:

buildNpmPackage rec {
  pname = "pin-github-action";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "v${version}";
    hash = "sha256-0YeBGMioUFkxi7moeVPv71Ww4EBYqHtwKbS/gtb1svU=";
    fetchSubmodules = true;
  };

  npmDepsHash = "sha256-+lda/Xh3Hh1d0nU5m3zmS0roy7Y9qAL8pOij807j2LE=";

  dontNpmBuild = true;

  passthru = {
    updateScript = nix-update-script { };
  };
}
