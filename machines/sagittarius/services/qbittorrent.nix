{ config, pkgs, ... }:
{
  services.qbittorrent = {
    enable = true;
    package = pkgs.unstable.qbittorrent-nox;
    webuiPort = 8081;
    openFirewall = false;
    serverConfig = {
      Preferences = {
        WebUI = {
          AuthSubnetWhitelist = "100.0.0.0/8";
          AuthSubnetWhitelistEnabled = "true";
          UseUPnP = "false";
        };
      };
    };
  };

  nginx.subdomain.qb."/".extraConfig = # nginx
    "return 302 http://sagittarius:${toString config.services.qbittorrent.webuiPort}$request_uri;";

  users.users.nregner.extraGroups = [ config.services.qbittorrent.group ];
}
