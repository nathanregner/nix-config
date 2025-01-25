{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  warnIfOutdated =
    prev: final:
    lib.warnIf (
      (lib.versionOlder final.version prev.version) || (final.version == prev.version)
    ) "${prev.pname} overlay can be removed. nixpkgs version: ${prev.version}" final;

  sharedModifications =
    final: prev:
    let
      stable = inputs.nixpkgs.legacyPackages.${final.system};
    in
    rec {
      hydra_unstable = prev.hydra_unstable.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./hydra/fix-restrict-eval-does-not-allow-access-to-git-flake.patch
          ./hydra/feat-add-always_supported_system_types-option.patch
        ];
        checkPhase = "";
      });

      # FIXME: hack to bypass "FATAL: Module ahci not found" error
      # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

      wrapNeovimUnstable =
        args: neovim-unwrapped:
        (prev.wrapNeovimUnstable args neovim-unwrapped).overrideAttrs {
          dontStrip = true;
        };

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
