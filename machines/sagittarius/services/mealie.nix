{
  config,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/mealie";
in
{
  services.mealie = {
    enable = true;
    package = pkgs.mealie;
    port = 9000;
  };

  nginx.subdomain.mealie = {
    "/".proxyPass = "http://127.0.0.1:${toString config.services.mealie.port}/";
  };

  local.services.backup.paths.mealie = {
    dynamicFilesFrom = "realpath ${dataDir}";
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
