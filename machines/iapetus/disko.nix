{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-uuid/432fbe74-ed01-4696-aecb-59028c69531b";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
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
            root = {
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
      };
    };
  };

  # https://github.com/nix-community/disko/issues/192
  fileSystems."/boot".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
}
