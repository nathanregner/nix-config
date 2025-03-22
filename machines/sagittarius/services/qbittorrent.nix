{ config, pkgs, ... }:
{
  services.qbittorrent = {
    enable = true;
    package = pkgs.unstable.qbittorrent-nox;
    port = 8081;
    openFirewall = false;
    settings = {
      Preferences = {
        "WebUI\\AuthSubnetWhitelist" = "100.0.0.0/8";
        "WebUI\\AuthSubnetWhitelistEnabled" = "true";
        "WebUI\\UseUPnP" = "false";
      };
    };
  };

  nginx.subdomain.qb."/".extraConfig = # nginx
    "return 302 http://sagittarius:${toString config.services.qbittorrent.port}$request_uri;";

  users.users.nregner.extraGroups = [ config.services.qbittorrent.group ];
}
