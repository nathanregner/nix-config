{ config, pkgs, ... }:
{
  services.moonraker = {
    enable = true;
    package = pkgs.unstable.moonraker;
    allowSystemControl = true;
    settings = {
      authorization = {
        cors_domains = [
          "*://voron.nregner.net"
          "*://voron"
          "http://localhost*"
        ];
        trusted_clients = [
          "127.0.0.0/8"
          "::1/128"
          "192.168.0.0/16"
          "100.0.0.0/8"
        ];
      };
      # required by KAMP
      file_manager.enable_object_processing = "True";
      history = { };
      # https://moonraker.readthedocs.io/en/latest/configuration/#spoolman
      spoolman = {
        server = "https://spoolman.nregner.net";
      };
    };
  };

  local.services.backup.jobs.moonraker = {
    root = config.services.moonraker.stateDir;
  };

  # required for allowSystemControl
  security.polkit.enable = true;

  # systemd.services.moonraker.environment.MOONRAKER_VERBOSE_LOGGING = "y";

  virtualisation.vmVariant = {
    # Open the port inside the guest firewall
    networking.firewall.allowedTCPPorts = [ config.services.spoolman.port ];

    services.spoolman.openFirewall = true;

    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = config.services.spoolman.port;
        guest.address = "127.0.0.1";
        guest.port = config.services.spoolman.port;
      }
    ];

    services.getty.autologinUser = "root";
  };
}
