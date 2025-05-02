{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  services.klipper = {
    enable = true;
    package = pkgs.unstable.klipper;
    user = "moonraker";
    group = "moonraker";
    configFile = pkgs.writeText "printer.cfg" ''
      [include /etc/klipper/printer.cfg]
    '';
    # mutableConfig = true;
  };

  environment.etc = {
    "klipper/KAMP".source = pkgs.local.klipper-adaptive-meshing-purging;
    "klipper/printer.cfg".source = pkgs.writeText "printer.immutable.cfg" ''
      [include ${./printer.cfg}]
      [include ${./kamp.cfg}]
      [include ${./menu.cfg}]
    '';
  };

  # restart Klipper when printer is powerd on
  # https://github.com/Klipper3d/klipper/issues/835
  services.udev.extraRules = ''
    ACTION=="add", ATTRS{idProduct}=="614e", ATTRS{idVendor}=="1d50", RUN+="${pkgs.systemd}/bin/systemctl restart klipper.service"
  '';

  # use bleeding edge
  disabledModules = [ "services/misc/klipper.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/klipper.nix" ];

  nixpkgs.overlays = [
    (final: prev: {
      # build without massive gui dependencies
      # TODO: submit patch to nixpkgs to make optional?
      klipper-firmware = final.unstable.klipper-firmware.overrideAttrs (prev: {
        nativeBuidlInputs = builtins.filter (
          pkg: lib.strings.hasPrefix "wxwidgets" pkg.name
        ) prev.nativeBuildInputs;
      });
    })
  ];
}
