{ inputs, outputs, config, lib, pkgs, ... }: {
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  nix = {
    distributedBuilds = true;
    package = lib.mkDefault pkgs.unstable.nix;

    settings = {
      auto-optimise-store = true;
      builders-use-substitutes = true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      trusted-users = [ "@wheel" "nregner" ];

      substituters = [
        "http://sagittarius:8000?priority=99&trusted=1"
        "https://nathanregner-mealie-nix.cachix.org"
      ];
      connect-timeout = 5;

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

