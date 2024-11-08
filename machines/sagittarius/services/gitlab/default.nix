{
  config,
  pkgs,
  ...
}:
{
  services.gitlab = {
    enable = true;
    packages.gitlab = pkgs.unstable.gitlab;
    port = 8083;
    initialRootPasswordFile = config.sops.secrets.gitlab-initial-root-password.path;
    secrets = {
      dbFile = config.sops.secrets.gitlab-db.path;
      jwsFile = config.sops.secrets.gitlab-jws.path;
      otpFile = config.sops.secrets.gitlab-otp.path;
      secretFile = config.sops.secrets.gitlab-secret.path;
    };
  };

  sops.secrets = builtins.listToAttrs (
    builtins.map
      (key: {
        name = "gitlab-${key}";
        value = {
          inherit key;
          sopsFile = ./secrets.yaml;
          owner = config.services.gitlab.user;
        };
      })
      [
        "db"
        "initial-root-password"
        "jws"
        "otp"
        "secret"
      ]
  );

  nginx.subdomain.gitlab = {
    "/".proxyPass = "http://127.0.0.1:${toString config.services.gitlab.port}/";
  };

  services.nregner.backup.paths.gitea = {
    paths = [
      config.services.gitlab.statePath
      "${config.services.gitlab.statePath}/backup"
    ];
    restic = {
      s3 = { };
    };
  };
}
