{
  inputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = lib.mkForce [
      "vfat"
      "fat32"
      "exfat"
      "ext4"
      "btrfs"
      "ntfs"
    ];
    initrd.availableKernelModules = [
      "nvme"
      "ahci"
      "xhci_pci"
      "usbhid"
      "uas"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-uuid/432fbe74-ed01-4696-aecb-59028c69531b";
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

  # https://github.com/nix-community/disko/issues/192
  fileSystems."/boot".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;

  swapDevices = [ ];
  zramSwap.enable = true;

  hardware.nvidia = {
    # Modesetting is needed for most wayland compositors
    modesetting.enable = true;

    # Use the open source version of the kernel module
    # Only available on driver 515.43.04+
    # NB: Secondary GPU not happy with open source
    open = false;

    # Enable the nvidia settings menu
    nvidiaSettings = true;

    # Fix issues with suspend/resume on wayland
    powerManagement.enable = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package =
      if config.vfio.enable then
        config.boot.kernelPackages.nvidiaPackages.stable
      else
        config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # Fix issues with suspend/resume on wayland
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

  hardware.graphics.enable = true;

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp38s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
