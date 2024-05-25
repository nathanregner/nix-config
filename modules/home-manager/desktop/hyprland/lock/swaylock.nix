{ config, pkgs, lib, ... }: {
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
      {
        timeout = lockDisplayOffAfter;
        command = lockDisplayOff;
        resumeCommand = displayOn;
      }
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
}
