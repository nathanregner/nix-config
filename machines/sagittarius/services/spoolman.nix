{ self, config, ... }:
let
  dataDir = "/var/lib/spoolman";
in
{
  # TODO: upstream a "package" option
  nixpkgs.overlays = [ (final: _prev: { inherit (final.unstable) spoolman; }) ];

  services.spoolman = {
    enable = true;
    listen = "0.0.0.0";
    inherit (self.globals.services.spoolman) port;
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

  nginx.subdomain.spoolman."/" = {
    proxyPass = "http://127.0.0.1:${toString self.globals.services.spoolman.port}/";
    # https://oauth2-proxy.github.io/oauth2-proxy/configuration/integration/
    # https://docs.gitea.com/administration/config-cheat-sheet?_highlight=reverse_proxy_authentication_email#security-security
  };

  services.oauth2-proxy = {
    nginx.virtualHosts."spoolman.nregner.net" = { };
  };
}
