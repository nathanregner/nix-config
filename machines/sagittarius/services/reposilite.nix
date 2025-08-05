{ config, pkgs, ... }:
{
  services.reposilite = {
    enable = true;
    package = pkgs.unstable.reposilite;
    settings = {
      port = 8083;
    };
    plugins = with pkgs.unstable.reposilitePlugins; [
      checksum
      swagger
    ];
    # FIXME
    extraArgs = [
      "--token"
      "admin:tailscale"
    ];
  };

  nginx.subdomain.maven."/".extraConfig = # nginx
    "return 302 http://sagittarius:${toString config.services.reposilite.settings.port}$request_uri;";
}
