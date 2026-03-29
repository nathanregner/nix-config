{ lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/nixos/base/nix.nix
    ./disko.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS requires a hostId
  networking.hostId = "deadbeef";
  networking.hostName = "qemu-test";

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  boot.initrd.systemd.enable = true;

  # Basic user for testing
  users.users.root.initialPassword = "test";
  users.users.test = {
    isNormalUser = true;
    initialPassword = "test";
    extraGroups = [ "wheel" ];
  };

  # Enable SSH for access
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # Minimal packages
  environment.systemPackages = [ ];

  # Allow unfree (for ZFS if needed)
  nixpkgs.config.allowUnfree = true;

  # Disable firewall for testing
  networking.firewall.enable = false;

  system.stateVersion = "25.11";
}
