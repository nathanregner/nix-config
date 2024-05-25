{ config, pkgs, ... }:
{
  services.moonraker = {
    enable = true;
    package = pkgs.moonraker-develop;
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
      history = { };
      # required by KAMP
      file_manager.enable_object_processing = "True";
    };
  };

  services.nregner.backups.moonraker = {
    paths = [ config.services.moonraker.stateDir ];
    restic = {
      s3 = { };
    };
  };

  # required for allowSystemControl
  security.polkit.enable = true;
}
