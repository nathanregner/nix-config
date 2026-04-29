{
  inputs,
  pkgs,
  lib,
  outputs,
  ...
}:
{
  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  nix = {
    package = pkgs.unstable.nix;
    distributedBuilds = true;
    optimise.automatic = true;

    settings = {
      auto-optimise-store = lib.mkDefault false;
      builders-use-substitutes = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      # https://github.com/NixOS/nix/issues/9087
      inherit (pkgs.local) flake-registry;
      trusted-users = [
        "@wheel"
        "nregner"
      ];

      substituters = [ "https://cache.nregner.net?trusted=1" ];
      connect-timeout = 5;

      trusted-public-keys = [ "default:h0V4pJnSGtvqgGKLO3KF0VJ0iOaiVBfa4OjmnnR2ob8=" ];
    };
  };
}
