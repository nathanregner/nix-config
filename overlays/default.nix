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
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

      # FIXME: https://github.com/NixOS/nixpkgs/issues/357979
      moonraker = warnIfOutdated prev.moonraker (final.callPackage ./moonraker { });

      # disable xvfb-run tests to fix build on darwin
      xdot =
        (prev.xdot.overridePythonAttrs (oldAttrs: {
          nativeCheckInputs = [ ];
        })).overrideAttrs
          (oldAttrs: {
            doInstallCheck = false;
          });

      wrapNeovimUnstable =
        args: neovim-unwrapped:
        (prev.wrapNeovimUnstable args neovim-unwrapped).overrideAttrs {
          dontStrip = true;
        };
    };
in
rec {
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
      overlays = [
        (_: _: additions stablePrev stableFinal)
        sharedModifications
      ];
    };
  };
}
