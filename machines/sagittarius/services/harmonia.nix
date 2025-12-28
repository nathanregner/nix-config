{ pkgs, ... }:
let
  port = 8000;
in
{
  services.harmonia = {
    enable = true;
    package = pkgs.unstable.harmonia;
    settings = {
      bind = "[::]:${toString port}";
    };
  };

  nginx.subdomain.cache = {
    "/".proxyPass = "http://127.0.0.1:${toString port}/";
  };
}
