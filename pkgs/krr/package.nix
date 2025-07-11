{
  inputs,
  pkgs,
  nix-update-script,
  ...
}:
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
    _final: prev:
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
mkPoetryApplication rec {
  version = "1.24.0";
  projectDir = pkgs.fetchFromGitHub {
    owner = "robusta-dev";
    repo = "krr";
    rev = "v${version}";
    sha256 = "sha256-2Kj94Co+4JV/ikLBUFqV4BdwFJSzvsbchf6As9U7LpQ=";
  };
  inherit overrides;

  dontCheckRuntimeDeps = true;
  doCheck = false;

  passthru.updateScript = nix-update-script { };
}
