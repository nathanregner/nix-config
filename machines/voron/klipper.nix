{ inputs, pkgs, ... }: {
  services.klipper = {
    enable = true;
    user = "moonraker";
    group = "moonraker";
    configFile = ./printer.cfg;
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
}
