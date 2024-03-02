{ inputs, outputs, config, lib, pkgs, ... }: {
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  nix = {
    # bump to fix https://github.com/NixOS/nix/issues/9591
    package = let pkg = pkgs.unstable.nixVersions.nix_2_19;
    in assert (lib.versionAtLeast pkg.version pkgs.unstable.nix.version); pkg;

    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      trusted-users = [ "@wheel" ];

      substituters = [
        "http://sagittarius:8000?priority=99&trusted=1"
        "https://nathanregner-mealie-nix.cachix.org"
      ];

      trusted-public-keys = [
        "default:h0V4pJnSGtvqgGKLO3KF0VJ0iOaiVBfa4OjmnnR2ob8="
        "nathanregner-mealie-nix.cachix.org-1:Ir3Z9UXjCcKwULpHZ8BveGbg7Az7edKLs4RPlrM1USM="
      ];
    };
  };

  # show config changes on switch
  # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/33
  system.activationScripts.report-changes = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.nvd config.nix.package ]}
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
  '';
}

