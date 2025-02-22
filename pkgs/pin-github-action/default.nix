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
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "v${version}";
    hash = "sha256-eeOnPQiBKXOx42M/JenzhPeZCZ/krLxhRyaAETPe4CM=";
    fetchSubmodules = true;
  };

  npmDepsHash = "sha256-2Y7pouKyfjMyejbktmBHhKqycp28MuGG7ZW8/9O1LYY=";

  dontNpmBuild = true;

  passthru = {
    updateScript = nix-update-script { };
  };
}
