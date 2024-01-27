{ hostname, config, lib, pkgs, ... }:
let cfg = config.print-farm.klipper;
in {
  options.print-farm.klipper = {
    enable = lib.mkEnableOption (lib.mkDoc "Enable Klipper profile");

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Klipper base config";
    };
    productId = lib.mkOption {
      type = lib.types.string;
      description = "USB product ID";
    };
    vendorId = lib.mkOption {
      type = lib.types.string;
      description = "USB vendor ID";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = let ports = [ 80 81 7125 ];
    in {
      allowedTCPPorts = ports;
      allowedUDPPorts = ports;
    };

    # klipper
    services.klipper = {
      enable = true;
      package = pkgs.unstable.klipper;
      user = "moonraker";
      group = "moonraker";
      configFile = pkgs.writeText "printer.cfg" ''
        [include /etc/klipper/printer.cfg]
      '';
      mutableConfig = true;
    };

    environment.etc."klipper/printer.cfg".source =
      pkgs.writeText "printer.immutable.cfg" ''
        [include ${cfg.configFile}]
        [include ${./macros.cfg}]
        [include ${./mainsail.cfg}]
      '';

    # restart Klipper when printer is powered on
    # https://github.com/Klipper3d/klipper/issues/835
    services.udev.extraRules = ''
      ACTION=="add", ATTRS{idProduct}=="614e", ATTRS{idVendor}=="1d50", RUN+="${pkgs.bash} -c 'systemctl restart klipper.service'"
    '';

    # moonraker
    services.moonraker = {
      enable = true;
      package = pkgs.moonraker-develop;
      allowSystemControl = true;
      address = "0.0.0.0";
      settings = {
        authorization = {
          cors_domains = [ "*://*.nregner.net" "*://${hostname}" ];
          trusted_clients = [ "127.0.0.0/8" "192.168.0.0/16" "100.0.0.0/8" ];
        };
        history = { };
      };
    };

    # required for allowSystemControl
    security.polkit.enable = true;

    # mainsail
    services.mainsail = { enable = true; };
    services.nginx = { clientMaxBodySize = "1G"; };
  };
}
