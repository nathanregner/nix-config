{ config, pkgs, ... }:
{
  services.gitea = {
    enable = true;
    package = pkgs.unstable.gitea;
    lfs = {
      enable = true;
    };
    settings = {
      server = {
        DOMAIN = "git.nregner.net";
        LFS_ALLOW_PURE_SSH = true;
        ROOT_URL = "https://git.nregner.net/";
        SSH_DOMAIN = "sagittarius";
        SSH_PORT = 30022;
        START_SSH_SERVER = true;
      };
      service = {
        DISABLE_REGISTRATION = true;
        ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
        ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true;
        ENABLE_REVERSE_PROXY_EMAIL = true;
      };
    };
  };

  nginx.subdomain.git."/" = {
    proxyPass = "http://127.0.0.1:${toString config.services.gitea.settings.server.HTTP_PORT}/";
    # https://oauth2-proxy.github.io/oauth2-proxy/configuration/integration/
    # https://docs.gitea.com/administration/config-cheat-sheet?_highlight=reverse_proxy_authentication_email#security-security
    extraConfig = # nginx
      ''
        client_max_body_size 0;

        proxy_set_header X-WEBAUTH-USER $user;
        proxy_set_header X-WEBAUTH-EMAIL $email;
      '';
  };

  services.oauth2-proxy = {
    nginx.virtualHosts."git.nregner.net" = {
      allowed_emails = [ "nathanregner@gmail.com" ];
    };
  };

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

    environment = {
      GITEA_URL = "http://localhost:${toString config.services.gitea.settings.server.HTTP_PORT}/api/v1";
    };

    serviceConfig = {
      EnvironmentFile = config.sops.secrets.gitea-github-mirror.path;
      User = "gitea";
    };

    script = ''
      ${pkgs.local.gitea-github-mirror}/bin/gitea-github-mirror
    '';
  };

  services.nregner.backup.paths.gitea = {
    paths = [ config.services.gitea.stateDir ];
    restic = {
      s3 = { };
    };
  };
}
