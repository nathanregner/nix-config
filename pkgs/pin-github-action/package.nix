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
  version = "3.1.2";

  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "v${version}";
    hash = "sha256-IjMMckPx76/Dyj9WDYcRBuXJOz4ZP8SR1SdPn2WV80c=";
    fetchSubmodules = true;
  };

  npmDepsHash = "sha256-nDOWeolGbaZK98yQnz+Aoe6kzgHd1PqzTCcKFjyJhu4=";

  dontNpmBuild = true;

  passthru = {
    updateScript = nix-update-script { };
  };
}
