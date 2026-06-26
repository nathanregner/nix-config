{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  # relativeWorktree support https://github.com/NixOS/nix/issues/14987
  assertions = [
    {
      assertion = lib.versionAtLeast config.nix.package.version "2.33.0";
      message = "${config.nix.package.version} < 2.33.0";
    }
  ];

  nixpkgs = import ../../../nixpkgs.nix { inherit inputs outputs; };

  nix = {
    package = pkgs.unstable.nixVersions.latest;
    distributedBuilds = true;
    optimise.automatic = true;

    settings = {
      auto-allocate-uids = true;
      auto-optimise-store = lib.mkDefault false;
      builders-use-substitutes = true;
      experimental-features = [
        "auto-allocate-uids"
        "cgroups"
        "flakes"
        "nix-command"
        "pipe-operators"
      ];
      extra-system-features = [ "uid-range" ];

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
