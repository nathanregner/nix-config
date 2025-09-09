{
  inputs,
  config,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/mealie";
in
{
  disabledModules = [ "services/web-apps/mealie.nix" ];
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/mealie.nix" ];
  nixpkgs.overlays = [ (final: prev: { nltk-data = final.unstable.nltk-data; }) ];

  services.mealie = {
    enable = true;
    package = pkgs.unstable.mealie;
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
