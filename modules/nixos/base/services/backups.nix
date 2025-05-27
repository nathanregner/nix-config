{
  options,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.local.services.backup;
in
{
  options.local.services.backup.enable = mkOption {
    default = !(options.virtualisation ? qemu);
  };

  # TODO: error if no files
  options.local.services.backup.paths = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule {
        options =
          (lib.getAttrs [
            "dynamicFilesFrom"
            "paths"
            "timerConfig"
          ] (options.services.restic.backups.type.getSubOptions [ ]))
          // {
            restic = mkOption {
              type = types.submodule {
                options = {
                  s3 = mkOption {
                    type = types.attrs; # TODO
                  };
                };
              };
            };
          };
      }
    );
  };

  config = lib.mkMerge [
    {
      # https://discourse.nixos.org/t/psa-pinning-users-uid-is-important-when-reinstalling-nixos-restoring-backups/21819
      local.services.backup.paths.nixos = {
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
            repository = "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${config.networking.hostName}/${name}";
            initialize = true;
            passwordFile = config.sops.secrets.restic-password.path;
            environmentFile = config.sops.secrets.restic-s3-env.path;
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
              restic ? { },
              ...
            }@opts:
            attrsets.mapAttrs' (type: job: {
              name = "${name}-${type}";
              value = ((defaults.${type} or (_: { })) name) // job // (builtins.removeAttrs opts [ "restic" ]);
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
