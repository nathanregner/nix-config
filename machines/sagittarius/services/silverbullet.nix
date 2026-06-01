{ config, pkgs, ... }:
{
  services.silverbullet = {
    enable = true;
    package = pkgs.unstable.silverbullet;
    listenPort = 3003;
  };

  nginx.subdomain.notes = {
    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.silverbullet.listenPort}/";
    };
    oauth2-proxy = { };
  };

  local.services.backup.jobs.silverbullet = {
    root = config.services.silverbullet.spaceDir;
  };
}
