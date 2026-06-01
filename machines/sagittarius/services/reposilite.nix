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
    # FIXME: if public access
    extraArgs = [
      "--token"
      "admin:tailscale"
    ];
  };
  nginx.subdomain.maven = {
    locations = {
      "/" = {
        return = "307 http://${config.networking.hostName}:${toString config.services.reposilite.settings.port}$request_uri";
      };
    };
  };

  local.services.backup.jobs.reposilite = {
    root = config.services.reposilite.workingDirectory;
    exclude = [
      "*.log"
      ".local"
      "logs"
      "static"
    ];
  };
}
