{ inputs, lib, modulesPath, pkgs, ... }: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/minimal.nix"
    ../../common/global
    ../../common/server
    ../../common/server/netdata/agent.nix
    ./klipper.nix
    ./mainsail.nix
    ./moonraker.nix
    ./networking.nix
  ];

  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
  networking.hostName = "voron";

  users.users.root = {
    password = "root"; # ssh password auth disabled, so whatever :)
  };

  boot = {
    kernelPackages = pkgs.linuxPackagesFor
      (pkgs.callPackage ./kernel { src = inputs.linux-rockchip; });

    supportedFilesystems = lib.mkForce [ "vfat" "fat32" "exfat" "ext4" ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    initrd.includeDefaultModules = false;
  };

  powerManagement.cpuFreqGovernor = "ondemand";

  hardware = {
    enableRedistributableFirmware = true;
    deviceTree = {
      name = "rockchip/rk3588s-orangepi-5.dtb";
      overlays = [
        {
          name = "orangepi5-sata-overlay";
          dtsText = ''
            // Orange Pi 5 Pcie M.2 to sata
            /dts-v1/;
            /plugin/;

            / {
              compatible = "rockchip,rk3588s-orangepi-5";

              fragment@0 {
                target = <&sata0>;

                __overlay__ {
                  status = "okay";
                };
              };

              fragment@1 {
                target = <&pcie2x1l2>;

                __overlay__ {
                  status = "disabled";
                };
              };
            };
          '';
        }
        {
          name = "orangepi5-i2c-overlay";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
              compatible = "rockchip,rk3588s-orangepi-5";

              fragment@0 {
                target = <&i2c1>;

                __overlay__ {
                  status = "okay";
                  pinctrl-names = "default";
                  pinctrl-0 = <&i2c1m2_xfer>;
                };
              };
            };
          '';
        }
      ];
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
