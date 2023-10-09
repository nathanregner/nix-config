{ config, pkgs, ... }: {
  sops.secrets.restic-password.key = "restic_password";
  sops.secrets.restic-s3-env.key = "restic/s3_env";
  services.restic.backups = {
    tandoor-recipes = {
      # TODO:
      # user = "backups";
      package = pkgs.unstable.restic;
      repository =
        "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic-${config.networking.hostName}/tandoor-recipes";
      initialize = true;
      passwordFile = config.sops.secrets.restic-password.path;
      environmentFile = config.sops.secrets.restic-s3-env.path;
      paths = [ "/var/lib/tandoor-recipes" ];
    };
  };
}
