{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.local.niri =
    let
      inherit (lib) types mkOption;
    in
    {
      enable = lib.mkEnableOption "Enable Niri configuration";

      # monitors = mkOption {
      #   description = "https://wiki.hyprland.org/Configuring/Monitors/";
      #   type = types.listOf (
      #     types.submodule {
      #       options = {
      #         name = mkOption { type = types.str; };
      #         resolution = mkOption { type = types.str; };
      #         position = mkOption { type = types.str; };
      #         scale = mkOption {
      #           type = types.int;
      #           default = 1;
      #         };
      #         workspaces = mkOption {
      #           type = types.listOf types.int;
      #           default = [ ];
      #         };
      #       };
      #     }
      #   );
      # };

      # wallpaper = mkOption { type = types.path; };
    };

  config =
    let
      cfg = config.local.niri;
    in
    lib.mkIf cfg.enable {
      xdg.configFile = {
        "niri/config.kdl" = {
          source = config.lib.file.mkFlakeSymlink ./config.kdl;
          force = true;
        };
      };

      home.packages = with pkgs.unstable; [
        niri
      ];
    };
}
