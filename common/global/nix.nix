{ self, lib, pkgs, outputs, ... }: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };

    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      trusted-users = [ "nregner" ];
      substituters = [ "http://sagittarius:8080/default" ];
      trusted-public-keys =
        [ "default:h0V4pJnSGtvqgGKLO3KF0VJ0iOaiVBfa4OjmnnR2ob8=" ];
      auto-optimise-store = true;
    };
  };

  # https://www.reddit.com/r/NixOS/comments/16t2njf/small_trick_for_people_using_nixos_with_flakes
  environment.etc."nixos-flake".source = ../..;
  system.nixos.tags = [ self.sourceInfo.shortRev or "dirty" ];

  # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/33
  system.activationScripts.report-changes = ''
    PATH=$PATH:${lib.makeBinPath [ pkgs.nvd pkgs.nix ]}
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
  '';
}
