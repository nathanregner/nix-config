{ inputs, lib, pkgs, ... }: {

  services.klipper.settings = { exclude_object = { }; };

  services.moonraker.settings = {
    file_manager.enable_object_processing = true;
  };

  # use bleeding edge
  disabledModules = [ "services/misc/klipper.nix" ];
  imports =
    [ "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/klipper.nix" ];

  nixpkgs.overlays = [
    (final: prev: {
      inherit (final.unstable) klipper;

      # build without massive gui dependencies
      # TODO: submit patch to nixpkgs to make optional?
      klipper-firmware = final.unstable.klipper-firmware.overrideAttrs (prev: {
        nativeBuidlInputs =
          builtins.filter (pkg: lib.strings.hasPrefix "wxwidgets" pkg.name)
          prev.nativeBuildInputs;
      });
    })
  ];
}
