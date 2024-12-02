{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  warnIfOutdated =
    prev: final:
    lib.warnIf (lib.versionOlder final.version prev.version)
      "${final.name} is outdated. latest: ${prev.version}"
      final;

  sharedModifications =
    final: prev:
    let
      stable = inputs.nixpkgs.legacyPackages.${final.system};
    in
    rec {
      inherit (inputs.clojure-lsp.packages.${final.system}) clojure-lsp;

      # FIXME: hack to bypass "FATAL: Module ahci not found" error
      # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
      hydra_unstable = prev.hydra_unstable.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./hydra/fix-restrict-eval-does-not-allow-access-to-git-flake.patch
          ./hydra/feat-add-always_supported_system_types-option.patch
        ];
        checkPhase = "";
      });

      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

      # FIXME: https://github.com/NixOS/nixpkgs/issues/357979
      moonraker = warnIfOutdated prev.moonraker (final.callPackage ./moonraker { });

      nodejs_latest = final.nodejs_20;

      # disable xvfb-run tests to fix build on darwin
      xdot =
        (prev.xdot.overridePythonAttrs (oldAttrs: {
          nativeCheckInputs = [ ];
        })).overrideAttrs
          (oldAttrs: {
            doInstallCheck = false;
          });
    };
in
{
  additions =
    final: _prev:
    import ../pkgs {
      inherit inputs;
      pkgs = final;
    };

  modifications =
    final: prev:
    {
    }
    // sharedModifications final prev;

  unstable-packages = stablePrev: stableFinal: {
    unstable = import inputs.nixpkgs-unstable {
      system = stableFinal.system;
      config.allowUnfree = true;
      overlays = [ sharedModifications ];
    };
  };
}
