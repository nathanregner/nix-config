{ config, ... }: {
  sops.secrets.restic-password.key = "restic/password";
  sops.secrets.restic-s3-env.key = "restic/s3";
  services.restic.backups = {
    tandoor-recipes = {
      # user = "backups";
      repository =
        "s3:https://s3.amazonaws.com/restic-${config.networking.hostName}/tandoor-recipes";
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      environmentFile = config.sops.secrets.restic-s3-env.path;
      paths = [ "/var/lib/tandoor-recipes" ];
    };
  };
}
