{ inputs, outputs }:
let
  inherit (inputs.nixpkgs) lib;

  filterPackagesRecursive = import ../lib/filterPackagesRecursive.nix lib;
  overlaysFromDirectoryRecursive = import ../lib/overlaysFromDirectoryRecursive.nix lib;
in
rec {
  additions =
    _final: prev:
    let
      inherit (prev.stdenv.hostPlatform) system;
    in
    {
      local = filterPackagesRecursive system outputs.legacyPackages.${system};
    };

  modifications = overlaysFromDirectoryRecursive ./shared;

  unstable-packages = stableFinal: _stablePrev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (stableFinal.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      overlays = [
        (_final: _prev: { inherit (stableFinal) local; })
        modifications
        (final: _: {
          tree-sitter-latest =
            (import (stableFinal.applyPatches {
              name = "nixpkgs-unstable";
              src = inputs.nixpkgs-unstable;
              patches = [ ./nixpkgs-482787.patch ];
            }) { inherit (stableFinal.stdenv.hostPlatform) system; }).tree-sitter;
        })
      ];
    };
  };
}
