{ self, inputs, outputs, config, lib, pkgs, ... }: {
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  nix = {
    package = lib.mkDefault pkgs.unstable.nix;

    # remove nix-channel related tools & configs
    channel.enable = false;

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      dates = "weekly";
    };

    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      trusted-users = [ "@wheel" ];

      substituters = [
        "http://sagittarius:8080/default?priority=10"
        "https://cache.nixos.org?priority=9"
      ];

      trusted-public-keys =
        [ "default:h0V4pJnSGtvqgGKLO3KF0VJ0iOaiVBfa4OjmnnR2ob8=" ];
    };
  };

  system.nixos.tags = [ self.sourceInfo.shortRev or "dirty" ];

  # show config changes on switch
  # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/33
  system.activationScripts.report-changes = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.nvd config.nix.package ]}
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
  '';
}
