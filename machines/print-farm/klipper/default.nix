{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.print-farm.klipper;
in
{
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

    # klipper
    services.klipper = {
      enable = true;
      package = pkgs.unstable.klipper;
      user = "moonraker";
      group = "moonraker";
      configFile = pkgs.writeText "printer.cfg" ''
        [include /etc/klipper/printer.cfg]

        [bltouch]
        z_offset: 3.998
      '';
      mutableConfig = true;
    };

    environment.etc = {
      "klipper/KAMP".source = pkgs.local.klipper-adaptive-meshing-purging;
      "klipper/adxl.cfg".source = ./adxl.cfg;
      "klipper/printer.cfg".source = pkgs.writeText "printer.immutable.cfg" ''
        [include ${cfg.configFile}]
        # [include /etc/klipper/adxl.cfg]
        [include ${./macros.cfg}]
        [include ${./mainsail.cfg}]
        [include ${./kamp.cfg}]
      '';
    };

    # restart Klipper when printer is powered on
    # https://github.com/Klipper3d/klipper/issues/835
    services.udev.extraRules = ''
      ACTION=="add", ATTRS{idProduct}=="614e", ATTRS{idVendor}=="1d50", RUN+="${pkgs.systemd}/bin/systemctl restart klipper.service"
    '';

    services.prometheus.exporters.klipper.enable = true;

    # moonraker
    services.moonraker = {
      enable = true;
      package = pkgs.unstable.moonraker;
      # package = pkgs.writeShellScriptBin "moonraker" ''
      #   ${pkgs.unstable.moonraker}/bin/moonraker -v $@
      # '';
      allowSystemControl = true;
      address = "0.0.0.0";
      settings = {
        authorization = {
          cors_domains = [ "*" ];
          trusted_clients = [
            "127.0.0.0/8"
            "192.168.0.0/16"
            "100.0.0.0/8"
          ];
        };
        history = { };
        # required by KAMP
        file_manager.enable_object_processing = "True";
      };
    };

    # required for allowSystemControl
    security.polkit.enable = true;

    # mainsail
    services.mainsail = {
      enable = true;
      package = pkgs.unstable.mainsail;
    };
    services.nginx = {
      clientMaxBodySize = "1G";
    };

    networking.firewall =
      let
        ports = [
          config.services.nginx.defaultHTTPListenPort
          config.services.moonraker.port
        ];
      in
      {
        allowedTCPPorts = ports;
        allowedUDPPorts = ports;
      };
  };
}
