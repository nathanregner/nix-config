{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.disko.nixosModules.disko ];

  # imports = [ inputs.orangepi-nix.nixosModules.zero2 ];
  # system.requiredKernelConfig = lib.mkForce [ ];
  nixpkgs.hostPlatform = "aarch64-linux";

  boot = {
    initrd.includeDefaultModules = false;
    loader = {
      grub.efiInstallAsRemovable = false;
      grub.efiSupport = false;
      systemd-boot.enable = false;
    };
    supportedFilesystems = lib.mkForce [ "f2fs" ];
  };

  hardware = {
    enableRedistributableFirmware = lib.mkForce false;
    enableAllFirmware = false;
  };

  powerManagement.cpuFreqGovernor = "ondemand";

  networking.interfaces.end1.useDHCP = true;

  nix.settings = {
    keep-outputs = false;
    keep-derivations = false;
  };

  fileSystems."/" = {
    fsType = lib.mkForce "f2fs";
    device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";
  };

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-label/NIXOS_SD";
      imageSize = "2G";
      content = {
        type = "gpt";
        partitions.root = {
          name = "root";
          end = "-0";
          content = {
            type = "filesystem";
            format = "f2fs";
            mountpoint = "/";
            extraArgs = [
              "-O"
              "extra_attr,inode_checksum,sb_checksum,compression"
            ];
            mountOptions = [
              "compress_algorithm=zstd:6,compress_chksum,atgc,gc_merge,lazytime,nodiscard"
            ];
          };
        };
        # partitions.root = {
        #   label = "NIXOS-ROOT";
        #   size = "100%";
        #   priority = 1;
        #   content = {
        #     type = "btrfs";
        #     extraArgs = [ "-f" ]; # Override existing partition
        #     subvolumes = {
        #       "root" = {
        #         mountpoint = "/";
        #         mountOptions = [
        #           "noatime"
        #         ];
        #       };
        #       "home" = {
        #         mountpoint = "/home";
        #         mountOptions = [
        #           "noatime"
        #         ];
        #       };
        #       "home-snapshots" = {
        #         mountpoint = "/home/.snapshots";
        #         mountOptions = [
        #           "noatime"
        #         ];
        #       };
        #       "nix" = {
        #         mountpoint = "/nix";
        #         mountOptions = [
        #           "noatime"
        #         ];
        #       };
        #       "@var" = { };
        #       "var-lib" = {
        #         mountpoint = "/var/lib";
        #         mountOptions = [
        #           "noatime"
        #         ];
        #       };
        #       "var-log" = {
        #         mountpoint = "/var/log";
        #         mountOptions = [
        #           "noatime"
        #         ];
        #       };
        #     };
        #   };
        # };
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
