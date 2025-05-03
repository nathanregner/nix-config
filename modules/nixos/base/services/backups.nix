{
  config,
  lib,
  utils,
  ...
}@args:
with lib;
let
  inherit (utils.systemdUtils.unitOptions) unitOption;
  cfg = config.services.nregner.backup;
in
{
  options.services.nregner.backup.enable = mkOption {
    default = !(args.options.virtualisation ? qemu);
  };

  options.services.nregner.backup.paths = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { config, name, ... }:
        {
          options = {
            paths = mkOption {
              type = types.listOf types.str;
              default = null;
              example = [
                "/var/lib/postgresql"
                "/home/user/backup"
              ];
            };

            timerConfig = mkOption {
              type = types.attrsOf unitOption;
              default = {
                OnCalendar = "3h";
                Persistent = true;
              };
              description = lib.mdDoc ''
                When to run the backup. See {manpage}`systemd.timer(5)` for details.
              '';
              example = {
                OnCalendar = "00:05";
                RandomizedDelaySec = "5h";
                Persistent = true;
              };
            };

            restic = mkOption {
              type = types.attrsOf (
                types.submodule (
                  { config, name, ... }:
                  {
                    # options = {
                    #   enable = mkOption {
                    #     type = types.bool;
                    #     default = true;
                    #   };
                    # };
                  }
                )
              );
            };
          };
        }
      )
    );
  };

  config = lib.mkMerge [
    {
      # https://discourse.nixos.org/t/psa-pinning-users-uid-is-important-when-reinstalling-nixos-restoring-backups/21819
      services.nregner.backup.paths.nixos = {
        paths = [ "/var/lib/nixos" ];
        restic = {
          s3 = { };
        };
      };
    }
    (lib.mkIf cfg.enable (
      let
        defaults = {
          s3 = name: {
            repository = "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${args.config.networking.hostName}/${name}";
            initialize = true;
            passwordFile = args.config.sops.secrets.restic-password.path;
            environmentFile = args.config.sops.secrets.restic-s3-env.path;
            # https://restic.readthedocs.io/en/stable/060_forget.html#removing-snapshots-according-to-a-policy
            pruneOpts = [
              "--keep-within 7d"
              "--keep-within-daily 1m"
              "--keep-within-weekly 6m"
              "--keep-within-monthly 1y"
            ];
          };
        };
        resticJobs = trivial.pipe cfg.paths [
          (attrsets.mapAttrsToList (
            name:
            {
              paths,
              restic ? { },
              ...
            }:
            attrsets.mapAttrs' (type: job: {
              name = "${name}-${type}";
              value = ((defaults.${type} or (_: { })) name) // job // { inherit paths; };
            }) restic
          ))
          (lists.foldl (acc: attrs: acc // attrs) { })
        ];
      in

      {
        sops.secrets.restic-password.key = "restic_password";
        sops.secrets.restic-s3-env.key = "restic/s3_env";
        services.restic.backups = resticJobs;
      }
    ))
  ];
}
