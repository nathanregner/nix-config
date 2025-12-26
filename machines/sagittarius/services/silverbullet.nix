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
    };
  };

  local.services.backup.jobs.silverbullet = {
    root = config.services.silverbullet.spaceDir;
  };
}
