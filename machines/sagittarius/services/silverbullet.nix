{ config, pkgs, ... }:
{
  services.silverbullet = {
    enable = true;
    package = pkgs.unstable.silverbullet;
    listenPort = 3003;
  };

  nginx.subdomain.notes = {
    "/" = {
      proxyPass = "http://localhost:${toString config.services.silverbullet.listenPort}/";
    };
  };

  services.oauth2-proxy = {
    nginx.virtualHosts."notes.nregner.net" = {
      allowed_emails = [ "nathanregner@gmail.com" ];
    };
  };

  local.services.backup.paths.silverbullet = {
    paths = [ config.services.silverbullet.spaceDir ];
    restic = {
      s3 = { };
    };
  };
}
