{ inputs, config, pkgs, lib, ... }:
let
  # to debug CSS:
  #
  # systemctl edit --user waybar
  #
  # [Service]
  # Environment="GTK_DEBUG=interactive"
  configFiles = {
    "waybar/style.css".source = config.lib.file.mkFlakeSymlink ./style.css;
  };
in {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    package = inputs.nixpkgs-wayland.packages.${pkgs.system}.waybar;
    # TODO: try https://github.com/polybar/polybar instead
    # https://www.reddit.com/r/unixporn/comments/s6s6sv/bspwm_catppuccin_is_a_pretty_cool_theme/#lightbox
    settings.mainBar = let
      styleIcon = icon: ''<span size="12pt">${icon}</span>'';
      iconFormat = styleIcon "{icon}";
    in {
      layer = "bottom";
      position = "top";
      height = 30;
      tray = { icon-size = 24; };

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "hyprland/window" ];
      modules-right = [
        "custom/weather"
        "custom/storage"
        "backlight"
        "pulseaudio"
        "network"
        "idle_inhibitor"
        "battery"
        "clock"
      ];

      backlight = {
        format = iconFormat;
        format-alt = "{percent}% ${iconFormat}";
        format-alt-click = "click-right";
        format-icons = [ "" "" ];
        on-scroll-down = "light -A 1";
        on-scroll-up = "light -U 1";
      };

      battery = {
        format = "{capacity}% ${iconFormat}";
        format-alt = "{time} ${iconFormat}";
        format-charging = "{capacity}% ";
        format-icons = [ "" "" "" "" "" ];
        interval = 30;
        states = {
          critical = 10;
          warning = 25;
        };
        tooltip = false;
      };

      clock = {
        format = "{:%a %d %b %H:%M:%S}";
        interval = 1;
      };

      idle_inhibitor = {
        format = iconFormat;
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
      };

      network = {
        format = iconFormat;
        format-alt = "{ipaddr}/{cidr} ${iconFormat}";
        format-alt-click = "click-right";
        format-icons = {
          disconnected = [ "" ];
          ethernet = [ "󰈀" ];
          wifi = [ "" "" "" ];
        };
        # on-click = "nmtui";
      };

      pulseaudio = {
        format = iconFormat;
        format-alt = "{volume} ${iconFormat}";
        format-alt-click = "click-right";
        format-icons = {
          default = [ "" "" "" "" ];
          phone = [ " " " " " " " " ];
        };
        format-muted = "";
        on-click = lib.getExe (pkgs.unstable.pavucontrol);
        scroll-step = 10;
        tooltip = true;
      };

      "custom/storage" = {
        exec = lib.getExe (pkgs.writeBabashkaApplication {
          name = "waybar-storage";
          text = builtins.readFile ./modules/storage.clj;
          runtimeInputs = [ pkgs.coreutils ];
        });
        format = "{}  ${styleIcon ""}";
        format-alt = "{percentage}%  ${styleIcon ""}";
        format-alt-click = "click-right";
        interval = 60;
        return-type = "json";
      };

      # "custom/weather" = {
      #   exec = "~/.config/waybar/modules/weather.sh";
      #   exec-if = "ping wttr.in -c1";
      #   format = "{}";
      #   format-alt = "{alt}: {}";
      #   format-alt-click = "click-right";
      #   interval = 1800;
      #   return-type = "json";
      # };

      "hyprland/window" = { separate-outputs = true; };
      "hyprland/workspaces" = { };
    };
  };

  xdg.configFile = configFiles;

  systemd.user.paths.waybar-watcher = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Path = {
      PathChanged = (builtins.map (path: "${config.xdg.configHome}/${path}")
        (builtins.attrNames configFiles));
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  systemd.user.services.waybar-watcher = {
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart waybar.service";
    };
  };
}
