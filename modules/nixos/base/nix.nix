{
  outputs,
  sources,
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs = import ../../../nixpkgs.nix { inherit outputs; };

  nix = {
    package = pkgs.unstable.nixVersions.latest;
    distributedBuilds = true;
    optimise.automatic = true;

    settings = {
      auto-optimise-store = lib.mkDefault false;
      builders-use-substitutes = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # https://github.com/NixOS/nix/issues/9087
      flake-registry = pkgs.runCommandLocal "flake-registry.json" { } ''
        cp ${sources.flake-registry.src}/flake-registry.json $out
      '';
      trusted-users = [
        "@wheel"
        "nregner"
      ];

      substituters = [ "https://cache.nregner.net?trusted=1" ];
      connect-timeout = 5;

      trusted-public-keys = [ "default:h0V4pJnSGtvqgGKLO3KF0VJ0iOaiVBfa4OjmnnR2ob8=" ];
    };
  };

  warnings = (
    lib.optional (lib.versionOlder config.nix.package.version pkgs.nix.version) "`nix.package` is outdated (${config.nix.package.version} < ${pkgs.nix.version})"
  );

  # show config changes on switch
  # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/33
  system.activationScripts.report-changes = ''
    ${pkgs.nvd}/bin/nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2) || true
  '';
}
