{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.klipper-stack;
  toINI = lib.generators.toINI { mkKeyValue = lib.generators.mkKeyValueDefault { } ": "; };
in
{
  options.klipper-stack = {
    includes = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Config files to include (linked to /etc/klipper/)";
    };
    config = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Klipper printer configuration (merged with includes)";
    };
    mutableConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Mutable config wrapper (includes immutable + runtime-editable settings)";
    };
    productId = lib.mkOption {
      type = lib.types.str;
      description = "USB product ID";
    };
    vendorId = lib.mkOption {
      type = lib.types.str;
      description = "USB vendor ID";
    };
  };

  config = {

    # klipper
    services.klipper = {
      enable = true;
      package = pkgs.unstable.klipper;
      user = "moonraker";
      group = "moonraker";
      configFile = pkgs.writeText "printer.cfg" (''
        [include /etc/klipper/includes.cfg]

        ${toINI cfg.config}
      '');
      mutableConfig = true;
    };

    environment.etc = {
      "klipper/KAMP".source = pkgs.local.klipper-adaptive-meshing-purging;
      "klipper/adxl.cfg".source = ./adxl.cfg;
      "klipper/includes.cfg".source = pkgs.concatTextFile {
        name = "klipper-includes.cfg";
        files = cfg.includes;
      };
    };

    # restart Klipper when printer is powered on
    # https://github.com/Klipper3d/klipper/issues/835
    services.udev.extraRules = ''
      ACTION=="add", ATTRS{idProduct}=="614e", ATTRS{idVendor}=="1d50", RUN+="${pkgs.systemd}/bin/systemctl restart klipper.service"
    '';

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
