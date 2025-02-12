{ config, pkgs, ... }:
let
  dataDir = "/var/lib/mealie";
in
{
  services.mealie = {
    enable = true;
    package = pkgs.unstable.mealie;
    port = 9000;
  };

  nginx.subdomain.mealie = {
    "/".proxyPass = "http://127.0.0.1:${toString config.services.mealie.port}/";
  };

  services.nregner.backup.paths.mealie = {
    paths = [ dataDir ];
    restic = {
      s3 = { };
    };
  };

  assertions = [
    {
      assertion = config.systemd.services.mealie.environment.DATA_DIR == dataDir;
      message = ''
        Mismatched config.systemd.services.mealie.environment.DATA_DIR: ${config.systemd.services.mealie.environment.DATA_DIR}
      '';
    }
  ];
}
