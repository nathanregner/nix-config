{ pkgs, ... }:
let
  port = 8000;
in
{
  services.harmonia = {
    cache = {
      enable = true;
      settings = {
        bind = "[::]:${toString port}";
        priority = 30;
      };
    };
    package = pkgs.unstable.harmonia;
  };

  nginx.subdomain.cache = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}/";
    };
  };
}
