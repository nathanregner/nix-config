{ config }:
{
  services.nexus = {
    enable = true;
    listenPort = 8082;
  };
  nginx.subdomain.nexus = {
    "/".proxyPass = "http://127.0.0.1:${toString config.services.nexus.listenPort}/";
  };
}
