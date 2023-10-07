{ inputs, config, pkgs, ... }: {
  imports = [ inputs.hyprland.homeManagerModules.default ./waybar ];

  xdg.configFile."hypr/user.conf".source =
    config.lib.file.mkFlakeSymlink ./hyprland.conf;

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      source=${config.xdg.configHome}/hypr/user.conf
    '';
  };

  # programs.wpaperd = {
  #   enable = true;
  #   settings = {
  #     default = {
  #       path = builtins.fetchurl rec {
  #         name = "wallpaper-${sha256}.png";
  #         url =
  #           "https://raw.githubusercontent.com/rxyhn/wallpapers/main/catppuccin/cat_leaves.png";
  #         sha256 = "1894y61nx3p970qzxmqjvslaalbl2skj5sgzvk38xd4qmlmi9s4i";
  #       };
  #     };
  #   };
  # };

  systemd.user.services.swaybg = let
    wallpaper = builtins.fetchurl rec {
      name = "wallpaper-${sha256}.png";
      url =
        "https://raw.githubusercontent.com/rxyhn/wallpapers/main/catppuccin/cat_leaves.png";
      sha256 = "1894y61nx3p970qzxmqjvslaalbl2skj5sgzvk38xd4qmlmi9s4i";
    };
  in {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg --mode fill --image ${wallpaper}";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  # home.packages = with pkgs.unstable;
  #   [
  #     hyprpaper # https://github.com/hyprwm/hyprpaper
  #   ];
}

