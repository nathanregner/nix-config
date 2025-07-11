{
  inputs,
  lib,
  callPackage,
  fetchFromGitHub,
  python311,
  srcOnly,
  stdenv,
  ...
}:
let
  python = python311;

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = srcOnly rec {
      pname = "krr";
      version = "1.24.0";
      src = fetchFromGitHub {
        owner = "robusta-dev";
        repo = "krr";
        rev = "v${version}";
        sha256 = "sha256-2Kj94Co+4JV/ikLBUFqV4BdwFJSzvsbchf6As9U7LpQ=";
      };
      # uvx migrate-to-uv
      patches = [ ./uv.patch ];
      inherit stdenv;
    };
  };

  # Create package overlay from workspace.
  overlay = workspace.mkPyprojectOverlay {
    # Prefer prebuilt binary wheels as a package source.
    # Sdists are less likely to "just work" because of the metadata missing from uv.lock.
    # Binary wheels are more likely to, but may still require overrides for library dependencies.
    sourcePreference = "wheel"; # or sourcePreference = "sdist";
    # Optionally customise PEP 508 environment
    # environ = {
    #   platform_release = "5.10.65";
    # };
  };

  pyprojectOverrides = _final: _prev: {
    # Implement build fixups here.
    # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
    # It's using https://pyproject-nix.github.io/pyproject.nix/build.html
    grapheme = python.pkgs.grapheme;
  };

  pythonSet =
    # Use base package set from pyproject.nix builders
    (callPackage inputs.pyproject-nix.build.packages { inherit python; }).overrideScope (
      lib.composeManyExtensions [
        inputs.pyproject-build-systems.overlays.default
        overlay
        pyprojectOverrides
      ]
    );

  inherit (callPackage inputs.pyproject-nix.build.util { }) mkApplication;
in
mkApplication {
  venv = pythonSet.mkVirtualEnv "application-env" workspace.deps.default;
  package = pythonSet.robusta-krr;
}
