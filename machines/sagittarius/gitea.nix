{ config, pkgs, ... }: {
  services.gitea = {
    enable = true;
    package = pkgs.unstable.gitea;
    lfs = { enable = true; };
    settings = {
      service.DISABLE_REGISTRATION = true;
      server.DOMAIN = "git.nregner.net";
      server.SSH_PORT = 30022;
    };
  };

  nginx.subdomain.git = {
    "/".proxyPass = "http://127.0.0.1:${
        toString config.services.gitea.settings.server.HTTP_PORT
      }/";
  };

  sops.secrets.gitea-github-mirror = { };

  systemd.timers.gitea-github-mirror = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    wantedBy = [ "timers.target" ];

    timerConfig = { OnCalendar = "daily"; };
  };

  systemd.services.gitea-github-mirror = {
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];

    serviceConfig = {
      EnvironmentFile = config.sops.secrets.gitea-github-mirror.path;
    };

    script = ''
      ${pkgs.gitea-github-mirror}/bin/gitea-github-mirror
    '';
  };

  services.backups.gitea = {
    paths = [ config.services.gitea.stateDir ];
    restic = { s3 = { }; };
  };
}
