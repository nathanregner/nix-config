{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  assertVersion =
    version: pkg:
    lib.throwIf (
      version != pkg.version
    ) "${pkg.pname or "???"} has been updated: ${version} -> ${pkg.version}" pkg;

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
      # FIXME
      # https://github.com/NixOS/nixpkgs/issues/305779
      # https://github.com/betaflight/betaflight-configurator/issues/3947
      betaflight-configurator = (assertVersion "10.10.0" prev.betaflight-configurator).override {
        nwjs = prev.nwjs.overrideAttrs rec {
          version = "0.84.0";
          src = prev.fetchurl {
            url = "https://dl.nwjs.io/v${version}/nwjs-v${version}-linux-x64.tar.gz";
            hash = "sha256-VIygMzCPTKzLr47bG1DYy/zj0OxsjGcms0G1BkI/TEI=";
          };
        };
      };

      hydra_unstable = prev.hydra_unstable.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
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
