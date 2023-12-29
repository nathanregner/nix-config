{ inputs, lib, pkgs, ... }: {
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    ../../modules/nixos/server/default.nix
    ../../modules/nixos/server/home-manager.nix
    ./hardware-configuration.nix
    ./attic.nix
    ./gitea.nix
    ./k8s.nix
    ./mealie.nix
    ./networking.nix
    ./nginx.nix
  ];

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  time.timeZone = "America/Boise";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "console=tty0" ];
  boot.supportedFilesystems =
    lib.mkForce [ "vfat" "fat32" "exfat" "ext4" "btrfs" ];

  users.users.root = {
    password = "root"; # ssh password auth disabled, so whatever :)
  };

  virtualisation.docker = {
    enable = true;
    package = pkgs.unstable.docker_24;
    daemon.settings = {
      live-restore = false;
      insecure-registries = [ "http://sagittarius:5000" ];
    };
  };

  environment.systemPackages = with pkgs; [ attic docker-compose ];
  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 5000;
  };

  sops.defaultSopsFile = ./secrets.yaml;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
