{ self, config, ... }:
{
  services.restic.server = {
    enable = true;

    dataDir = "/vol/backup/restic";
    htpasswd-file = config.sops.secrets.restic-server-httpasswd.path;
    listenAddress = "[::]:${toString self.globals.services.restic-server.port}";
    privateRepos = true;
  };

  sops.secrets.restic-server-httpasswd = {
    key = "restic/server/htpasswd";
    group = "restic";
    mode = "0440";
  };
}
