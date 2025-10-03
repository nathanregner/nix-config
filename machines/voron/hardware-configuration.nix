{
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-cpu-intel
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelParams = [ "console=tty0" ];
    supportedFilesystems = lib.mkForce [
      "vfat"
      "fat32"
      "exfat"
      "ext4"
      "btrfs"
    ];
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "ehci_pci"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  powerManagement.cpuFreqGovernor = "ondemand";

  # hardware.enableRedistributableFirmware = false;

  networking.interfaces.end1.useDHCP = true;

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0";
      content = {
        type = "gpt";
        partitions.ESP = {
          label = "NIXOS-BOOT";
          type = "EF00";
          size = "1G";
          priority = 1;
          # bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        partitions.root = {
          label = "NIXOS-ROOT";
          size = "100%";
          priority = 2;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # Override existing partition
            subvolumes = {
              "root" = {
                mountpoint = "/";
                mountOptions = [
                  "noatime"
                ];
              };
              "home" = {
                mountpoint = "/home";
                mountOptions = [
                  "noatime"
                ];
              };
              "home-snapshots" = {
                mountpoint = "/home/.snapshots";
                mountOptions = [
                  "noatime"
                ];
              };
              "nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "noatime"
                ];
              };
              "@var" = { };
              "var-lib" = {
                mountpoint = "/var/lib";
                mountOptions = [
                  "noatime"
                ];
              };
              "var-log" = {
                mountpoint = "/var/log";
                mountOptions = [
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
    nodev = {
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=16G"
        ];
      };
    };
  };
}
