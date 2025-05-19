{ pkgs, ... }:
let
  port = 8084;
in
{
  services.ntfy-sh = {
    package = pkgs.unstable.ntfy-sh;
    enable = true;
    settings = {
      base-url = "https://ntfy.nregner.net";
      behind-proxy = true;
      listen-http = ":${toString port}";
    };
  };

  nginx.subdomain.cache = {
    "/".proxyPass = "http://127.0.0.1:${toString port}/";
  };
}
