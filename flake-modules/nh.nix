{
  flake.modules.nixos.nh =
    { pkgs, ... }:
    {
      programs.nh = {
        enable = true;
        package = pkgs.unstable.nh;
        clean = {
          enable = true;
          extraArgs = "--keep 2 --keep-since 14d";
        };
      };
    };

  flake.modules.darwin.nh =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = [ pkgs.unstable.nh ];

      # https://github.com/nix-darwin/nix-darwin/issues/1307
      nix = {
        gc.automatic = lib.mkForce false;
        optimise.automatic = lib.mkForce false;
      };
    };

  flake.modules.homeManager.nh =
    { config, pkgs, ... }:
    {
      programs.nh = {
        enable = true;
        package = pkgs.unstable.nh;
        clean = {
          enable = true;
          extraArgs = "--keep 2 --keep-since 3d";
        };

        flake = "${config.home.homeDirectory}/nix-config/local";
      };
    };
}
