{
  inputs,
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
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
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-uuid/bed76273-18ca-45c6-9008-93a5332f7608";
    content = {
      type = "gpt";
      partitions.boot = {
        label = "nixos-boot";
        type = "EF00";
        size = "1G";
        priority = 1;
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
        };
      };
      partitions.root = {
        label = "nixos-root";
        size = "100%";
        priority = 2;
        content = {
          type = "btrfs";
          extraArgs = [ "-f" ]; # Override existing partition
          subvolumes = {
            "@" = {
              mountpoint = "/";
              mountOptions = [ "noatime" ];
            };
            "@home" = {
              mountpoint = "/home";
              mountOptions = [ "noatime" ];
            };
            "@home-snapshots" = {
              mountpoint = "/home/.snapshots";
              mountOptions = [ "noatime" ];
            };
            "@nix" = {
              mountpoint = "/nix";
              mountOptions = [ "noatime" ];
            };
            "@var" = { };
            "@var-lib" = {
              mountpoint = "/var/lib";
              mountOptions = [ "noatime" ];
            };
            "@var-log" = {
              mountpoint = "/var/log";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };
    };
  };

  disko.devices.disk.data = {
    type = "disk";
    device = "/dev/disk/by-uuid/394db84b-1663-4d06-9cfa-794c3162bd93";
    content = {
      type = "gpt";
      partitions.root = {
        label = "nixos-root";
        size = "100%";
        priority = 1;
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/vol/data";
        };
      };
    };
  };

  disko.devices.disk.backup = {
    type = "disk";
    device = "/dev/disk/by-uuid/dfe2646a-e49d-4d93-a118-7b1f1085db08";
    content = {
      type = "gpt";
      partitions.root = {
        label = "backup";
        size = "100%";
        priority = 1;
        content = {
          type = "btrfs";
          extraArgs = [ "-f" ]; # Override existing partition
          mountpoint = "/vol/backup";
        };
      };
    };
  };

  zramSwap.enable = true;
  swapDevices = [ ];

  networking = {
    useDHCP = true;
    interfaces.enp4s0.useDHCP = true;
    interfaces.enp5s0.useDHCP = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
