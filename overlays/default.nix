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
      # built from hydra's own scope (and pinned nixpkgs) so overlays/shared/hydra-dev can override
      # hydra-perl, which the `hydra` wrapper package is built from
      hydra-dev =
        let
          hydraPkgs = inputs.hydra.inputs.nixpkgs.legacyPackages.${system}.extend inputs.hydra.overlays.default;
        in
        hydraPkgs.hydra.overrideAttrs (oldAttrs: {
          passthru = (oldAttrs.passthru or { }) // {
            inherit (hydraPkgs) hydraComponents;
          };
        });
    };

  modifications = overlaysFromDirectoryRecursive ./shared;

  unstable-packages = stableFinal: _stablePrev: rec {
    unstable = import inputs.nixpkgs-unstable {
      inherit (stableFinal.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      overlays = [
        (_final: _prev: { inherit (stableFinal) local; })
        modifications
      ];
    };
    inherit (unstable) tmux;
  };
}
