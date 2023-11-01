{ inputs, outputs, lib, pkgs, ... }: {
  imports = [ ./. ./cli ./desktop ./desktop/gnome ./desktop/jetbrains ./nvim ];

  # standalone install - reimport nixpkgs
  nixpkgs = import ../nixpkgs.nix { inherit inputs outputs; };

  home.packages = with pkgs; [
    # apps
    openrgb

    # tools
    rclone
    restic
    screen

    # k8s
    kubectl
    kubernetes-helm

    # 3d printer
    unstable.super-slicer-latest
    # freecad-link
  ];

  programs.alacritty.settings = { font = { size = lib.mkForce 11; }; };

  services.easyeffects.enable = true;

  home = {
    username = "nregner";
    homeDirectory = "/home/nregner";
    flakePath = "/home/nregner/nix-config/iapetus";
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
