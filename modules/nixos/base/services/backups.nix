{
  options,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.local.services.backup;
  baseOptions = options.services.restic.backups.type.getSubOptions [ ];
  mkDefault = default: mkOption { inherit default; };
  mkReadonly =
    default:
    mkOption {
      inherit default;
      readOnly = true;
    };
  mkTarget =
    options:
    mkOption {
      type = types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
          };
        }
        // options
        // builtins.getAttrs baseOptions (
          builtins.attrNames (lib.filterAttrs (_name: option: !option.readOnly) options)
          ++ [
            "pruneOpts"
            "timerConfig"
          ]
        );
      };
    };

in
{
  options.local.services.backup.enable = mkOption {
    default = !(options.virtualisation ? qemu);
  };

  # TODO: error if no files
  options.local.services.backup.paths = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options =
            (lib.getAttrs [
              "dynamicFilesFrom"
              "paths"
              "timerConfig"
            ] baseOptions)
            // {
              restic = mkOption {
                type = types.submodule {
                  default = { };
                  options = {
                    s3 = mkTarget {
                      repository = mkReadonly "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${config.networking.hostName}/${name}";
                      initialize = mkReadonly true;
                      passwordFile = mkReadonly config.sops.secrets.restic-password.path;
                      environmentFile = mkReadonly config.sops.secrets.restic-s3-env.path;
                      pruneOpts = mkDefault [
                        "--keep-within 7d"
                        "--keep-within-daily 1m"
                        "--keep-within-weekly 6m"
                        "--keep-within-monthly 1y"
                      ];
                    };
                    hdd = mkTarget {
                      repository = mkReadonly "/vol/backup/restic/${name}";
                      initialize = mkReadonly true;
                      passwordFile = mkReadonly config.sops.secrets.restic-password.path;
                      environmentFile = mkReadonly config.sops.secrets.restic-s3-env.path;
                      pruneOpts = mkDefault [
                        "--keep-within 7d"
                        "--keep-within-daily 1m"
                        "--keep-within-weekly 6m"
                        "--keep-within-monthly 1y"
                      ];
                    };
                  };
                };
              };
            };
        }
      )
    );
  };

  config = lib.mkMerge [
    {
      # https://discourse.nixos.org/t/psa-pinning-users-uid-is-important-when-reinstalling-nixos-restoring-backups/21819
      local.services.backup.paths.nixos = {
        paths = [ "/var/lib/nixos" ];
      };
    }
    (lib.mkIf cfg.enable (
      let
        resticJobs = trivial.pipe cfg.paths [
          (attrsets.mapAttrsToList (
            name:
            {
              restic ? { },
              ...
            }@opts:
            attrsets.mapAttrs' (type: job: {
              name = "${name}-${type}";
              value = (builtins.removeAttrs job [ "enable" ]) // (builtins.removeAttrs opts [ "restic" ]);
            }) (attrsets.filterAttrs (_type: job: job.enable) restic)
          ))
          (lists.foldl (acc: attrs: acc // attrs) { })
        ];
      in
      {
        sops.secrets = {
          restic-password = {
            key = "restic_password";
            group = "restic";
            mode = "0440";
          };
          restic-s3-env = {
            key = "restic/s3_env";
            group = "restic";
            mode = "0440";
          };
        };

        users.groups.restic = {
        };

        services.restic.backups = resticJobs;
      }
    ))
  ];
}
