{ inputs, lib, pkgs, ... }: {
  services.klipper = {
    enable = true;
    user = "moonraker";
    group = "moonraker";
    configFile = pkgs.writeText "printer.cfg" ''
      [include /etc/klipper/printer.cfg]
    '';
    mutableConfig = true;
    firmwares = {
      mcu = {
        enable = true;
        configFile = ./firmware.cfg;
        serial =
          "/dev/serial/by-id/usb-Klipper_stm32f446xx_450016000450335331383520-if00";
      };
    };
  };

  environment.etc = {
    "klipper/KAMP".source = "${inputs.kamp}/Configuration";
    "klipper/printer.cfg".source = pkgs.writeText "printer.immutable.cfg" ''
      [include ${./printer.cfg}]
      [include ${./kamp.cfg}]
    '';
  };

  # restart Klipper when printer is powerd on
  # https://github.com/Klipper3d/klipper/issues/835
  services.udev.extraRules = ''
    ACTION=="add", ATTRS{idProduct}=="614e", ATTRS{idVendor}=="1d50", RUN+="${pkgs.bash} -c 'systemctl restart klipper.service'"
  '';

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
