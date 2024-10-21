{ inputs, pkgs, ... }:
let
  inherit (inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; })
    defaultPoetryOverrides
    mkPoetryApplication
    ;
  pypkgs-build-requirements = {
    about-time = [ "setuptools" ];
    alive-progress = [ "setuptools" ];
    prometheus-api-client = [ "setuptools" ];
  };
  overrides = defaultPoetryOverrides.extend (
    final: prev:
    builtins.mapAttrs (
      package: build-requirements:
      (builtins.getAttr package prev).overridePythonAttrs (old: {
        buildInputs =
          (old.buildInputs or [ ])
          ++ (builtins.map (
            pkg: if builtins.isString pkg then builtins.getAttr pkg prev else pkg
          ) build-requirements);
      })
    ) pypkgs-build-requirements
  );
in
mkPoetryApplication {
  # TODO: nvfetcher
  projectDir = pkgs.fetchFromGitHub {
    owner = "robusta-dev";
    repo = "krr";
    rev = "v1.16.0";
    fetchSubmodules = false;
    sha256 = "sha256-jPTSp/IBhhWzRg0qjakE7HOCgXAcgFJejePVRFIzAs0=";
  };
  inherit overrides;

  dontCheckRuntimeDeps = true;
  doCheck = false;
}
