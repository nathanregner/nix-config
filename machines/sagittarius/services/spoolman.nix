{ config, ... }:
let
  dataDir = "/var/lib/spoolman";
in
{
  # TODO: upstream a "package" option
  nixpkgs.overlays = [ (final: _prev: { inherit (final.unstable) spoolman; }) ];

  services.spoolman = {
    enable = true;
    listen = "0.0.0.0";
    # package = pkgs.unstable.spoolman;
    environment = {
      # SPOOLMAN_CORS_ORIGIN = "source1.domain.com:p1, source2.domain.com:p2";
      # SPOOLMAN_DB_TYPE = "sqlite";
      # SPOOLMAN_LOGGING_LEVEL = "DEBUG";
      # SPOOLMAN_METRICS_ENABLED = "TRUE";
    };
  };

  local.services.backup.jobs.spoolman = {
    dynamicFilesFrom = "realpath ${dataDir}";
  };

  assertions = [
    {
      assertion = config.systemd.services.spoolman.environment.SPOOLMAN_DIR_DATA == dataDir;
      message = ''
        Mismatched config.systemd.services.spoolman.environment.SPOOLMAN_DIR_DATA: ${config.systemd.services.spoolman.environment.SPOOLMAN_DIR_DATA}
      '';
    }
  ];
  nginx.subdomain.spoolman = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.spoolman.port}/";
      proxyWebsockets = true;
    };
    oauth2-proxy = { };
    trusted-ips = [
      "100.0.0.0/8" # tailscale
      "192.168.0.0/16" # local network
    ];
  };
}
