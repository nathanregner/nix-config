{
  config,
  modulesPath,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ./sd-image.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  zramSwap.enable = true;

  sdImage = {
    # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low on space.
    compressImage = true;
    imageName = "zero2.img";

    extraFirmwareConfig = {
      # Give up VRAM for more Free System Memory
      # - Disable camera which automatically reserves 128MB VRAM
      start_x = 0;
      # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
      gpu_mem = 16;

      # Configure display to 800x600 so it fits on most screens
      # * See: https://elinux.org/RPi_Configuration
      hdmi_group = 2;
      hdmi_mode = 8;
    };
  };

  # Keep this to make sure wifi works
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  boot = {
    # TODO doesn't work
    # kernelPackages = pkgs.linuxKernel.packages.linux_rpi3;

    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    # Avoids warning: mdadm: Neither MAILADDR nor PROGRAM has been set. This will cause the `mdmon` service to crash.
    # See: https://github.com/NixOS/nixpkgs/issues/254807
    swraid.enable = lib.mkForce false;
  };

  # Ugly hack to make it work with Pi Zero 2
  sdImage.populateRootCommands = lib.mkForce ''
    mkdir -p ./files/boot
    ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    DTBS_DIR=$(ls -d ./files/boot/nixos/*-dtbs)/broadcom
    chmod u+w $DTBS_DIR
    cp ${config.system.build.toplevel}/dtbs/broadcom/bcm2837-rpi-zero-2-w.dtb $DTBS_DIR/bcm2837-rpi-zero-2.dtb
    chmod u-w $DTBS_DIR
  '';
}
