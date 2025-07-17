{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # inputs.hyprland.homeManagerModules.default
    # TODO: opt-in to individual components options
    ./bar/waybar
    ./launcher/tofi.nix
    ./lock/hyprlock.nix
    ./notification/mako.nix
    ../wayland
  ];

  options =
    let
      inherit (lib) types mkOption;
    in
    {
      hyprland = {
        enable = lib.mkEnableOption "Enable Hyprland configuration";
        package = null;

        monitors = mkOption {
          description = "https://wiki.hyprland.org/Configuring/Monitors/";
          type = types.listOf (
            types.submodule {
              options = {
                name = mkOption { type = types.str; };
                resolution = mkOption { type = types.str; };
                position = mkOption { type = types.str; };
                scale = mkOption {
                  type = types.int;
                  default = 1;
                };
                workspaces = mkOption {
                  type = types.listOf types.int;
                  default = [ ];
                };
              };
            }
          );
        };

        wallpaper = mkOption { type = types.path; };
      };
    };

  config =
    let
      cfg = config.hyprland;
    in
    lib.mkIf cfg.enable {
      catppuccin.hyprland.enable = true;

      wayland.windowManager.hyprland = {
        enable = true;
        extraConfig = ''
          # Monitors
          ${lib.concatMapStringsSep "\n" (
            monitor:
            "monitor=${monitor.name},${monitor.resolution},${monitor.position},${toString monitor.scale}"
          ) cfg.monitors}

          # Workspaces
          ${lib.concatMapStringsSep "\n" (
            monitor:
            (lib.concatMapStringsSep "\n" (
              workspace: "workspace=${toString workspace},monitor:${monitor.name},persitent:true"
            ) monitor.workspaces)
          ) cfg.monitors}

          exec-once = import-env tmux
          exec-once = import-env system
          exec-once = nm-applet --indicator
          exec-once = blueman-applet
          exec-once = "systemctl --user start waybar.service"
          source = ${config.xdg.configHome}/hypr/hyprland.user.conf
        '';
      };

      xdg.configFile = {
        "hypr/hyprland.user.conf".source = config.lib.file.mkFlakeSymlink ./hyprland.conf;

        "hypr/hyprpaper.conf".text = ''
          splash = false
          preload = ~/.config/hypr/assets/wallpaper.png
          ${lib.concatMapStringsSep "\n" (
            monitor: "wallpaper=${monitor.name},~/.config/hypr/assets/wallpaper.png"
          ) cfg.monitors}
        '';

        "hypr/assets/wallpaper.png".source = cfg.wallpaper;
        "hypr/assets/avatar.png".source =
          pkgs.runCommand "avatar.png"
            {
              nativeBuildInputs = with pkgs.unstable; [ imagemagick ];
            }
            ''
              magick ${../../../../assets/cat.png} -resize 100x100 $out
            '';
      };

      home.packages = with pkgs.unstable; [
        hyprpaper
        hyprpicker

      ];

      # auto mount disks
      services.udiskie.enable = true;
    };
}
