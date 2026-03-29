{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.disko-zfs.nixosModules.default
  ];

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/vda";
      imageSize = "10G";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            label = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          zfs = {
            label = "zfs";
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };

    zpool.zroot = {
      type = "zpool";

      options = {
        ashift = "12"; # force 4096 (some old SSDs lie for compatibility reasons)
        autotrim = "on";
      };

      # man zfsprops
      rootFsOptions = {
        xattr = "sa";
        dnodesize = "auto"; # consider setting dnodesize to auto if the dataset uses the xattr=sa
        acltype = "posixacl";
        compression = "zstd";
        atime = "off";
        mountpoint = "none";
        "com.sun:auto-snapshot" = "false";
      };

      # data = generic storage
      # local = never replicated
      datasets = {
        "local" = {
          type = "zfs_fs";
          options = {
            mountpoint = "none";
            canmount = "off";
          };
        };

        "data" = {
          type = "zfs_fs";
          options = {
            mountpoint = "none";
            canmount = "off";
          };
        };

        "data/root" = {
          type = "zfs_fs";
          mountpoint = "/";
        };

        "data/home" = {
          type = "zfs_fs";
          mountpoint = "/home";
        };

        "local/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    };

    nodev = {
      "/tmp" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=8G"
        ];
      };
    };
  };

  # Enable disko-zfs for declarative dataset management
  disko.zfs = {
    enable = true;
    settings = {
      logLevel = "info";
      # Datasets managed by disko-zfs (auto-populated from disko.devices.zpool)
      # Additional datasets can be declared here:
      # datasets = {
      #   "zroot/safe/persist/postgresql" = {
      #     properties.recordsize = "8K";
      #   };
      # };
    };
  };
}
