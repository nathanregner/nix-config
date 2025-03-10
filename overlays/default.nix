{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  warnIfOutdated =
    prev: final:
    lib.warnIf ((lib.versionOlder final.version prev.version) || (final.version == prev.version))
      "${final.pname or "???"} overlay can be removed. nixpkgs version: ${final.version} -> ${prev.version}"
      final;

  sharedModifications =
    final: prev:
    let
      stable = inputs.nixpkgs.legacyPackages.${final.system};
    in
    rec {
      hydra_unstable = prev.hydra_unstable.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./hydra/feat-add-always_supported_system_types-option.patch
        ];
        checkPhase = "";
      });

      # TODO: remove https://github.com/NixOS/nixpkgs/issues/387340
      tailscale = warnIfOutdated prev.tailscale stable.tailscale;

      # FIXME: hack to bypass "FATAL: Module ahci not found" error
      # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

      wrapNeovimUnstable =
        args: neovim-unwrapped:
        (prev.wrapNeovimUnstable args neovim-unwrapped).overrideAttrs {
          dontStrip = true;
          dontFixup = true;
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
    final: prev:
    builtins.mapAttrs
      (
        name: pkg:
        if builtins.hasAttr name prev && lib.isDerivation pkg then warnIfOutdated prev.${name} pkg else pkg
      )
      (
        import ../pkgs {
          inherit lib;
          pkgs = final;
        }
      );

  modifications =
    final: prev:
    {
    }
    // sharedModifications final prev;

  unstable-packages = stableFinal: stablePrev: {
    unstable = import inputs.nixpkgs-unstable {
      system = stableFinal.system;
      config.allowUnfree = true;
      overlays = [
        (
          final: prev:
          builtins.mapAttrs
            (
              name: pkg:
              if builtins.hasAttr name prev && lib.isDerivation pkg then warnIfOutdated prev.${name} pkg else pkg
            )
            (
              import ../pkgs {
                inherit lib;
                pkgs = stableFinal;
              }
            )
        )
        sharedModifications
      ];
    };
  };
}
