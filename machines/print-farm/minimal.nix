# https://discourse.nixos.org/t/how-to-have-a-minimal-nixos/22652/4
{ inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/profiles/headless.nix"
    "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
  ];

  # only add strictly necessary modules
  boot.initrd.includeDefaultModules = false;
  boot.initrd.kernelModules = [ "ext4" ];
  disabledModules = [
    "${inputs.nixpkgs}/nixos/modules/profiles/all-hardware.nix"
    "${inputs.nixpkgs}/nixos/modules/profiles/base.nix"
  ];

  # disable useless software
  environment.defaultPackages = [ ];
  xdg.icons.enable = false;
  xdg.mime.enable = false;
  xdg.sounds.enable = false;
}
