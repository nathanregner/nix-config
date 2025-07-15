{ inputs, outputs }:
let
  inherit (inputs.nixpkgs) lib;
  filterPackagesRecursive = import ../lib/filterPackagesRecursive.nix lib;

  assertVersion =
    version: pkg:
    lib.throwIf (
      version != pkg.version
    ) "${pkg.pname or "???"} has been updated: ${version} -> ${pkg.version}" pkg;

  assertLaterVersion =
    final: prev:
    lib.throwIf (lib.versionAtLeast prev.version final.version)
      "${prev.pname or "???"} has been updated: ${final.version} -> ${prev.version}"
      final;

  sharedModifications = final: prev: rec {
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

    # FIXME: Remove once https://github.com/newren/git-filter-repo/issues/659 is released
    git-filter-repo = (assertVersion "2.47.0" prev.git-filter-repo).overrideAttrs (_oldAttrs: {
      src = final.fetchFromGitHub {
        owner = "newren";
        repo = "git-filter-repo";
        rev = "2d391462dca14cd18b8faaefce34dc91dc1ae150";
        hash = "sha256-2jws/s36GuZrthODzj3OvlR9lDU9Nr1XIGNWRyO+0wA=";
      };

      checkPhase = ''
        make test
      '';
    });

    hydra = prev.hydra.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        ./hydra/feat-add-always_supported_system_types-option.patch
      ];
      doCheck = false;
    });

    # FIXME: hack to bypass "FATAL: Module ahci not found" error
    # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
    makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });

    # TODO: upstream https://github.com/Arksine/moonraker/issues/401
    moonraker = prev.moonraker.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches or [ ] ++ [
        ./moonraker/0001-file_manager-Add-config-option-to-rename-duplicate-f.patch
      ];
    });

    nix-prefetch = prev.nix-prefetch.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches or [ ] ++ [
        # https://github.com/msteen/nix-prefetch/pull/34
        ./nix-prefetch/34.patch
      ];
    });

    nix-update-script =
      args:
      [
        (lib.getExe final.nix-update)
        "--flake"
      ]
      ++ (lib.lists.tail (prev.nix-update-script args));

    wrapNeovimUnstable =
      args: neovim-unwrapped:
      (prev.wrapNeovimUnstable args neovim-unwrapped).overrideAttrs {
        dontStrip = true;
        dontFixup = true;
      };

    # disable xvfb-run tests to fix build on darwin
    xdot =
      (prev.xdot.overridePythonAttrs (_oldAttrs: {
        nativeCheckInputs = [ ];
      })).overrideAttrs
        (_oldAttrs: {
          doInstallCheck = false;
        });
  };
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

  modifications =
    final: prev:
    {
    }
    // sharedModifications final prev;

  unstable-packages = stableFinal: _stablePrev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (stableFinal) system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          inherit (stableFinal) local;

          nixVersions = prev.nixVersions // {
            latest = (assertLaterVersion prev.nixVersions.nix_2_30 prev.nixVersions.latest);
          };
        })
        sharedModifications
      ];
    };
  };
}
