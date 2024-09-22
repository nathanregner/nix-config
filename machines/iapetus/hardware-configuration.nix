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

  hardware.graphics = {
    enable = true;
    # Override broken nvidia config which depends on 32 bit `pkgsi686Linux.nvidia-vaapi-driver`
    # for `opengl.driSupport32Bit` which is enabled by the steam config.
    # https://github.com/NixOS/nixpkgs/blob/6d6682772b62652b5019ffd7572cea1f39b72b20/nixos/modules/hardware/video/nvidia.nix#L395C45-L395C45
    # https://github.com/skykanin/dotfiles/commit/a6c71c022efb8e4ec404f8718edd9661b850876f
    extraPackages32 = pkgs.lib.mkForce [ pkgs.linuxPackages_latest.nvidia_x11.lib32 ];
  };

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
