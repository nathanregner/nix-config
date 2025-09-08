{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.local.niri = {
    enable = lib.mkEnableOption "Enable Niri configuration";
    package = lib.mkPackageOption pkgs.unstable "niri" { };
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

      home.packages = [
        # cfg.package
        # (pkgs.writers.writeNuBin "niri-select-window" ./select-window.nu)
      ];

      services.gnome-keyring.enable = true;

      # programs.fuzzel.enable = true;
      # catppuccin.fuzzel.enable = true;
      catppuccin.rofi.enable = true;
      programs.rofi = {
        enable = true;
        package = pkgs.unstable.rofi-wayland;
        terminal = lib.getExe config.programs.alacritty.package;
      };

      services.swww.enable = true;
      systemd.user.services.swww.Service.ExecStartPost = ''
        ${lib.getExe' config.services.swww.package "swww"} img ${../../../../../../assets/planet-rise.png}
      '';
    };
}
