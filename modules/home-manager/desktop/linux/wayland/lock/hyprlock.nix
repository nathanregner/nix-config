{
  config,
  pkgs,
  lib,
  ...
}:
{
  catppuccin.hyprlock.enable = true;
  programs.hyprlock = {
    enable = true;
    package = pkgs.unstable.hyprlock;
    extraConfig = ''
      source=${config.xdg.configHome}/hypr/hyprlock.user.conf
    '';
  };

  xdg.configFile = {
    "hypr/hyprlock.user.conf".source = ./hyprlock.conf;
  };

  services.hypridle = {
    enable = true;
    package = pkgs.unstable.hypridle;
    settings = {
      general = {
        lock_cmd = "hyprlock"; # avoid starting multiple hyprlock instances
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 5 * 60;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 30 * 60;
          on-timeout = "hyprlock";
        }
        {
          timeout = 10;
          on-timeout = lib.getExe (
            pkgs.writeShellApplication {
              name = "hyprlock-active-display-timeout";
              runtimeInputs = [ pkgs.procps ];
              text = ''
                if pgrep -x hyprlock; then
                  hyprctl dispatch dpms off
                fi
              '';
            }
          );
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
