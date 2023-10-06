{ inputs, lib, pkgs, ... }: {
  imports = [
    inputs.nixos-generators.nixosModules.all-formats
    ../../common/global
    ../../common/server
    ./hardware-configuration.nix
    ./attic.nix
    ./k8s.nix
    ./networking.nix
    ./nginx.nix
    ./tandoor-recipes.nix
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
