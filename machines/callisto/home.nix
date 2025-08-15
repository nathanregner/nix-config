{ lib, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/desktop/linux/gnome
  ];

  home.packages = with pkgs; [
    # apps
    openrgb

    # tools
    rclone
    restic
    screen
  ];

  programs.alacritty.settings = {
    font = {
      size = lib.mkForce 11;
    };
  };

  home = {
    username = "nregner";
    homeDirectory = "/home/nregner";
    flakePath = "/home/nregner/nix-config/callisto";
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
