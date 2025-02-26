{ config, pkgs, ... }:
{
  services.gitea = {
    enable = true;
    package = pkgs.unstable.gitea;
    lfs = {
      enable = true;
    };
    settings = {
      service.DISABLE_REGISTRATION = true;
      server.DOMAIN = "git.nregner.net";
      server.SSH_PORT = 30022;
    };
  };

  nginx.subdomain.git = {
    "/".proxyPass = "http://127.0.0.1:${toString config.services.gitea.settings.server.HTTP_PORT}/";
  };

  sops.secrets."gickup/gitea_token" = { };
  sops.secrets."gickup/github_token" = { };

  services.gickup = {
    enable = true;
    configFile = pkgs.substituteAll {
      src = ./gickup.yml;
      gitea_token = config.sops.secrets."gickup/gitea_token".path;
      github_token = config.sops.secrets."gickup/github_token".path;
    };
    interval = "daily";
  };

  services.nregner.backup.paths.gitea = {
    paths = [ config.services.gitea.stateDir ];
    restic = {
      s3 = { };
    };
  };
}
