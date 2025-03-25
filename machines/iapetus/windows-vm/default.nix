{ lib, ... }:
{
  imports = [
    ./vfio.nix
    ./usb-libvirt-hotplug.nix
  ];
  virtualisation.libvirtd.enable = true;
  vfio.enable = lib.mkDefault false;
  specialisation."vfio".configuration = {
    system.nixos.tags = [ "vfio" ];
    vfio.enable = true;
  };
}
