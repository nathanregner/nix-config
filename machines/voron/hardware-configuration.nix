{
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.nixos-hardware.nixosModules.common-pc-ssd ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    initrd.includeDefaultModules = false;
  };

  powerManagement.cpuFreqGovernor = "ondemand";

  hardware.enableRedistributableFirmware = false;

  networking.interfaces.end1.useDHCP = true;

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
}
