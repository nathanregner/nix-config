{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices.disk.vda = {
    type = "disk";
    device = "/dev/disk/by-id/ata-CT1000MX500SSD4_1927E211B0B8";
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
            "@root" = {
              mountpoint = "/";
              mountOptions = [
                "compress=zstd:1"
                "noatime"
              ];
            };
            "@home" = {
              mountpoint = "/home";
              mountOptions = [
                "compress=zstd:1"
                "noatime"
              ];
            };
            "@nix" = {
              mountpoint = "/nix";
              mountOptions = [
                "compress=zstd:1"
                "noatime"
              ];
            };
            "@var" = { };
            "@var/lib" = {
              mountpoint = "/var/lib";
              mountOptions = [
                "compress=zstd:1"
                "noatime"
              ];
            };
            "@var/log" = {
              mountpoint = "/var/log";
              mountOptions = [
                "compress=zstd:1"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}
