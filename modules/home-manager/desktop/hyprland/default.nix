{ inputs, config, pkgs, ... }: {
  imports = [
    # inputs.hyprland.homeManagerModules.default
    ./waybar
    ./mako.nix
  ];

  xdg.configFile."hypr/user.conf".source =
    config.lib.file.mkFlakeSymlink ./hyprland.conf;

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      source=${inputs.catppuccin-hyprland}/themes/mocha.conf
      source=${config.xdg.configHome}/hypr/user.conf
    '';
  };

  home.packages = with pkgs; [ hyprpaper gnome.nautilus ];
}

