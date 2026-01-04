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
      ];
    };
  };
}
