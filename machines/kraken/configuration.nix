{ config, hostname, lib, modulesPath, nixpkgs, pkgs, ... }: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/minimal.nix"
    ../../common/global
    ../../common/server
    ./octoprint.nix
  ];

  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
  networking.hostName = hostname;

  users.users.root = {
    password = "root"; # ssh password auth disabled, so whatever :)
  };

  boot = {
    kernelPackages =
      pkgs.linuxPackagesFor pkgs.cross.linux_orange-pi-6_1-sun50iw9;
    kernelParams = [ "boot.shell_on_fail" ];
    kernelModules = [
      "sprdwl_ng" # wifi driver
    ];
    supportedFilesystems = lib.mkForce [ "vfat" "ext4" "ntfs" "cifs" ];
    consoleLogLevel = lib.mkDefault 7;

    initrd = { supportedFilesystems = lib.mkForce [ "vfat" "ext4" ]; };
    loader.generic-extlinux-compatible.enable = true;
    loader.grub.enable = false;
  };

  hardware = {
    firmware = with pkgs; [ cross.wcnmodem-firmware ];
    deviceTree = {
      name = "allwinner/sun50i-h616-orangepi-zero2.dtb";
      filter = "sun50i-h616-orangepi-zero2.dtb";
    };
  };

  sdImage = {
    postBuildCommands = ''
      # Emplace bootloader to specific place in firmware file
      dd if=/dev/zero of=$img bs=1k count=1023 seek=1 status=noxfer \
          conv=notrunc # prevent truncation of image
      dd if=${pkgs.cross.u-boot-v2021_10-sunxi}/u-boot-sunxi-with-spl.bin of=$img bs=1k seek=8 conv=fsync \
          conv=notrunc # prevent truncation of image
    '';
    compressImage = true;
  };

  # Networking
  sops.secrets.ddns.key = "route53-ddns/env";
  services.route53-ddns = {
    enable = true;
    domain = "${hostname}.nregner.net";
    ipType = "lan";
    ttl = 60;
    environmentFile = config.sops.secrets.ddns.path;
  };

  sops.secrets.wireless.sopsFile = ./secrets.yaml;
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
    environmentFile = config.sops.secrets.wireless.path;
    networks."4Cosands" = {
      priority = 1;
      psk = "@4Cosands@";
    };
    networks."CenturyLink2746" = {
      priority = 2;
      psk = "@CenturyLink2746@";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
