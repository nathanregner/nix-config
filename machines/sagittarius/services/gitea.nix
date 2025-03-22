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

  nginx.subdomain.git."/".extraConfig = # nginx
    "return 302 http://sagittarius:${toString config.services.gitea.settings.server.HTTP_PORT}$request_uri;";

  sops.secrets.gitea-github-mirror = { };

  systemd.timers.gitea-github-mirror = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "daily";
    };
  };

  systemd.services.gitea-github-mirror = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];

    serviceConfig = {
      EnvironmentFile = config.sops.secrets.gitea-github-mirror.path;
      User = "gitea";
    };

    script = ''
      ${pkgs.gitea-github-mirror}/bin/gitea-github-mirror
    '';
  };

  services.nregner.backup.paths.gitea = {
    paths = [ config.services.gitea.stateDir ];
    restic = {
      s3 = { };
    };
  };
}
