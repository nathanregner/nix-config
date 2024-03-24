{ inputs, ... }: rec {
  additions = final: _prev:
    import ../pkgs {
      inherit inputs;
      pkgs = final;
    };

  modifications = final: prev: {
    super-slicer-latest = prev.super-slicer-latest.overrideAttrs (oldAttrs: {
      # https://bugs.gentoo.org/924105
      patches = oldAttrs.patches ++ [
        ./super-slicer-latest/fix-MeshBoolean-const.patch
        ./super-slicer-latest/superslicer-2.5.59.8-boost-replace-load-string-file.patch
      ];
    });

    # TODO: assert not outdated
    nix-direnv = final.callPackage ./nix-direnv { };

    # FIXME: hack to bypass "FATAL: Module ahci not found" error
    # https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1350599022
    makeModulesClosure = x:
      prev.makeModulesClosure (x // { allowMissing = true; });
  };

  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
      overlays = [ modifications ];
    };
  };
}
