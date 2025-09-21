{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ inputs.nixos-hardware.nixosModules.common-pc-ssd ];

  boot = {
    supportedFilesystems = lib.mkForce [
      "vfat"
      "fat32"
      "exfat"
      "ext4"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    initrd.includeDefaultModules = false;
  };

  local.kernel = {
    enable = true;
    dir = ./kernel;
    packages = {
      kernel = pkgs.linuxKernel.packages.linux_6_16.kernel.overrideAttrs {
        name = "k"; # dodge uboot length limits
      };
      linux = pkgs.linuxKernel;
    };
  };

  assertions = [
    {
      assertion = lib.strings.versionAtLeast config.boot.kernelPackages.kernel.version pkgs.linuxPackages.kernel.version;
      message = ''
        Kernel is out of date: ${config.boot.kernelPackages.kernel.version} < ${pkgs.linuxPkgs.kernel.version}
      '';
    }
  ];

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

  networking.interfaces.end1.useDHCP = true;

  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
}
