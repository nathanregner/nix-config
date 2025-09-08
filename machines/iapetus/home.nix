{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop/linux/wayland
  ];

  home = {
    username = "nregner";
    homeDirectory = "/home/nregner";
    flakePath = "/home/nregner/nix-config/iapetus";
  };

  local.niri = {
    enable = true;
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
    gimp
    openrgb
    prismlauncher
    super-slicer-beta

    # cli
    awscli2
    gh
    nix-fast-build
    nushell
    rclone
    xdot
  ];

  programs.alacritty.settings = {
    font = {
      size = lib.mkForce 11;
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
