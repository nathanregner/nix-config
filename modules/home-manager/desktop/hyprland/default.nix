{ inputs, config, pkgs, lib, ... }: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./waybar
    ./mako.nix
    ./tofi.nix
  ];

  options = let inherit (lib) types mkOption;
  in {
    hyprland = {
      enable = lib.mkEnableOption "Enable Hyprland configuration";

      monitors = mkOption {
        description = "https://wiki.hyprland.org/Configuring/Monitors/";
        type = types.listOf (types.submodule {
          options = {
            name = mkOption { type = types.str; };
            resolution = mkOption { type = types.str; };
            position = mkOption { type = types.str; };
            scale = mkOption {
              type = types.int;
              default = 1;
            };
          };
        });
      };

      wallpaper = mkOption { type = types.path; };
    };
  };

  config = let
    cfg = config.hyprland;
    import-env =
      pkgs.writeShellScriptBin "import-env" (builtins.readFile ./import-env.sh);
  in lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      catppuccin.enable = true;

      extraConfig = ''
        ${lib.concatMapStringsSep "\n" (monitor:
          "monitor = ${monitor.name}, ${monitor.resolution}, ${monitor.position}, ${
            toString monitor.scale
          }") cfg.monitors}
        exec-once = ${lib.getExe import-env} tmux
        exec-once = ${lib.getExe import-env} system
        source = ${config.xdg.configHome}/hypr/user.conf
      '';
    };

    services.swayidle = let
      inherit (lib) getExe getExe';

      hyprctl = ''
        exec "${
          getExe' config.wayland.windowManager.hyprland.package "hyprctl"
        }"'';
      displayOff = "${hyprctl} dispatch dpms off";
      displayOn = "${hyprctl} dispatch dpms on";
      lockPackage = getExe config.programs.swaylock.package;
      lock = "${lockPackage}";
      lockDisplayOff = getExe (pkgs.writeShellApplication {
        name = "lock-display-off";
        runtimeInputs = [ pkgs.procps ];
        text = ''
          if pgrep -x ${lockPackage} || pgrep -x swaylock;
            then ${displayOff};
          fi
        '';
      });
      lockAfter = 5 * 60;
      lockDisplayOffAfter = 5;
    in {
      enable = true;

      timeouts = [
        # auto-lock
        {
          timeout = lockAfter;
          command = "${lock} --grace 15";
          resumeCommand = displayOn;
        }
        # turn off display after locking manually
        # {
        #   timeout = lockDisplayOffAfter;
        #   command = lockDisplayOff;
        #   resumeCommand = displayOn;
        # }
        # turn off display after locking automatically
        {
          timeout = lockAfter + lockDisplayOffAfter;
          command = lockDisplayOff;
          resumeCommand = displayOn;
        }
        # auto-sleep
        # {
        #   timeout = 15 * 60;
        #   command = "/run/current-system/sw/bin/systemctl suspend";
        # }
      ];

      events = [
        {
          event = "lock";
          command = lock;
        }
        {
          event = "before-sleep";
          command = lock;
        }
        {
          event = "after-resume";
          command = displayOn;
        }
      ];
    };

    programs.swaylock = {
      enable = true;
      package = pkgs.unstable.swaylock-effects;
      catppuccin.enable = true;
      settings = {
        daemonize = true;
        grace = 5;

        clock = true;
        effect-blur = "10x3";
        image = "~/.config/hypr/assets/wallpaper.png";
        indicator = true;
        show-failed-attempts = true;
      };
    };

    xdg.configFile = {
      "hypr/user.conf".source = config.lib.file.mkFlakeSymlink ./hyprland.conf;

      "hypr/hyprpaper.conf".text = ''
        splash = false
        preload = ~/.config/hypr/assets/wallpaper.png
        ${lib.concatMapStringsSep "\n" (monitor:
          "wallpaper = ${monitor.name}, ~/.config/hypr/assets/wallpaper.png")
        cfg.monitors}
      '';

      "hypr/assets/wallpaper.png".source = cfg.wallpaper;
      "hypr/assets/avatar.png".source = ../../../../assets/cat.png;
    };

    home.packages = with pkgs.unstable; [
      gnome.nautilus
      # TODO: Get these from the flake?
      hyprpaper
      hyprpicker
      import-env
    ];

    services.udiskie.enable = true;
  };
}

