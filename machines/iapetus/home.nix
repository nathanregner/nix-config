{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop
    ../../modules/home-manager/desktop/gnome
    ../../modules/home-manager/desktop/hyprland
  ];

  home = {
    username = "nregner";
    homeDirectory = "/home/nregner";
    flakePath = "/home/nregner/nix-config/iapetus";
  };

  hyprland = {
    enable = true;
    monitors = [
      {
        name = "desc:Ancor Communications Inc VG248 JBLMQS148602";
        resolution = "1920x1080@144";
        position = "0x0";
        workspaces = [
          1
          2
          3
          4
          5
        ];
      }
      {
        name = "desc:Ancor Communications Inc VG248 J6LMQS041978";
        resolution = "1920x1080@144";
        position = "1920x0";
        workspaces = [
          6
          7
          8
          9
          0
        ];
      }
    ];
    wallpaper = ../../assets/planet-rise.png;
  };

  programs.insync = {
    enable = true;
    extensions.nautilus.enable = true;
  };

  home.packages = with pkgs.unstable; [
    # apps
    betaflight-configurator
    cura-appimage
    discord
    evince
    gimp
    openrgb
    prismlauncher
    super-slicer-beta

    # nix
    xdot

    # rust
    cargo-autoinherit
    cargo-outdated

    # rc
    betaflight-configurator
  ];

  xdg.desktopEntries.discord = {
    type = "Application";
    name = "Discord";
    comment = "All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.";
    genericName = "Internet Messenger";
    # exec = "discord --enable-features=UseOzonePlatform --ozone-platform=wayland";
    exec = "discord --disable-gpu";
    icon = "discord";
    categories = [
      "Network"
      "InstantMessaging"
    ];
  };

  programs.alacritty.settings = {
    font = {
      size = lib.mkForce 11;
    };
  };

  services.easyeffects.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
