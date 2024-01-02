{ inputs, modulesPath, lib, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    ../../modules/nixos/disko-sd-image.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  fileSystems."/" = {
    fsType = lib.mkForce "btrfs";
    device = lib.mkForce "/dev/disk/by-label/disk-NIXOS_SD-root";
  };

  disko = {
    sdImage.disk = "NIXOS_SD";
    devices = {
      disk = {
        NIXOS_SD = {
          type = "disk";
          device = "/dev/vda";
          content = {
            type = "gpt";
            partitions = {
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Override existing partition
                  # Subvolumes must set a mountpoint in order to be mounted,
                  # unless their parent is mounted
                  subvolumes = {
                    # Subvolume name is different from mountpoint
                    "/rootfs" = { mountpoint = "/"; };
                    # Subvolume name is the same as the mountpoint
                    "/home" = {
                      mountOptions = [ "compress=zstd" ];
                      mountpoint = "/home";
                    };
                    # Sub(sub)volume doesn't need a mountpoint as its parent is mounted
                    "/home/user" = { };
                    # Parent is not mounted so the mountpoint must be set
                    "/nix" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/nix";
                    };
                    # This subvolume will be created but not mounted
                    "/test" = { };
                    # Subvolume for the swapfile
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap = {
                        swapfile.size = "20M";
                        swapfile2.size = "20M";
                        swapfile2.path = "rel-path";
                      };
                    };
                  };

                  mountpoint = "/partition-root";
                  swap = {
                    swapfile = { size = "20M"; };
                    swapfile1 = { size = "20M"; };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

