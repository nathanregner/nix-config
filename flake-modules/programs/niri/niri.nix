{
  flake.modules.nixos.niri =
    { pkgs, ... }:
    {
      # TODO: Launch directly, just use home-manager
      programs.niri = {
        enable = true;
        package = pkgs.unstable.niri;
      };

      services.displayManager = {
        defaultSession = "niri";
        gdm.enable = true;
      };
    };

  flake.modules.homeManager.niri =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      xdg.configFile = {
        "niri/config.kdl" = {
          source = config.lib.file.mkFlakeSymlink ./config.kdl;
          force = true;
        };
      };

      services.gnome-keyring.enable = true;

      # programs.fuzzel.enable = true;
      # catppuccin.fuzzel.enable = true;
      catppuccin.rofi.enable = true;
      programs.rofi = {
        enable = true;
        package = pkgs.unstable.rofi;
        terminal = lib.getExe config.programs.alacritty.package;
      };

      services.swww.enable = true;
      systemd.user.services.swww.Service.ExecStartPost = ''
        ${lib.getExe' config.services.swww.package "swww"} img ${../../../assets/planet-rise.png}
      '';
    };
}
