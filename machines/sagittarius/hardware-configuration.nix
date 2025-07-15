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
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  assertions = [
    {
      assertion = lib.versionAtLeast config.nix.package.version "2.30.0";
      message = "${config.nix.package.version} < 2.30.0";
    }
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

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bed76273-18ca-45c6-9008-93a5332f7608";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/bed76273-18ca-45c6-9008-93a5332f7608";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "noatime"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/bed76273-18ca-45c6-9008-93a5332f7608";
    fsType = "btrfs";
    options = [
      "subvol=@var-lib"
      "noatime"
    ];
  };

  fileSystems."/var/lib" = {
    device = "/dev/disk/by-uuid/bed76273-18ca-45c6-9008-93a5332f7608";
    fsType = "btrfs";
    options = [
      "subvol=@var-log"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/bed76273-18ca-45c6-9008-93a5332f7608";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A652-29E4";
    fsType = "vfat";
  };

  fileSystems."/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "size=32G"
    ];
  };

  fileSystems."/vol/data" = {
    device = "/dev/disk/by-uuid/394db84b-1663-4d06-9cfa-794c3162bd93";
    fsType = "ext4";
  };

  fileSystems."/vol/backup" = {
    device = "/dev/disk/by-uuid/dfe2646a-e49d-4d93-a118-7b1f1085db08";
    fsType = "btrfs";
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
