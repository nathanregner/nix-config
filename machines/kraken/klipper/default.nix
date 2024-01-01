{ hostname, pkgs, ... }: {
  nixpkgs.overlays = [ (final: prev: { inherit (final.unstable) moonraker; }) ];

  # klipper
  services.klipper = {
    enable = true;
    user = "moonraker";
    group = "moonraker";
    mutableConfig = true;
    configFile = ./printer-sunlu-s8-2020.cfg;
  };

  environment.systemPackages =
    [ pkgs.klipper-firmware-sunlu-s8.passthru.klipper-flash ];

  # restart Klipper when printer is powerd on
  # https://github.com/Klipper3d/klipper/issues/835
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", RUN+="${pkgs.bash} -c 'systemctl restart klipper.service'"
  '';

  # moonraker
  services.moonraker = {
    enable = true;
    allowSystemControl = true;
    address = "0.0.0.0";
    settings = {
      authorization = {
        cors_domains = [ "*://*.nregner.net" "*://${hostname}" ];
        trusted_clients = [ "127.0.0.0/8" "::1/128" "100.0.0.0/8" ];
      };
      history = { };
    };
  };

  # required for allowSystemControl
  security.polkit.enable = true;

  # mainsail
  services.mainsail = { enable = true; };
  services.nginx = { clientMaxBodySize = "1G"; };
  networking.firewall = let ports = [ 80 81 7125 ];
  in {
    allowedTCPPorts = ports;
    allowedUDPPorts = ports;
  };
}
