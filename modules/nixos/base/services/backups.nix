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
      types.submodule (
        { name, ... }:
        {
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
                    s3 =

                      let
                        s3Defaults = {
                          repository = "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${config.networking.hostName}/${name}";
                          initialize = true;
                          passwordFile = config.sops.secrets.restic-password.path;
                          environmentFile = config.sops.secrets.restic-s3-env.path;
                          pruneOpts = [
                            "--keep-within 7d"
                            "--keep-within-daily 1m"
                            "--keep-within-weekly 6m"
                            "--keep-within-monthly 1y"
                          ];
                        };
                      in
                      mkOption {
                        type = types.submodule {
                          options = {
                            enable = mkOption {
                              type = types.bool;
                              default = true;
                            };
                          }
                          // builtins.mapAttrs (
                            name: value:
                            mkOption {
                              readOnly = true;
                              default = value;
                            }
                          ) s3Defaults
                          // builtins.removeAttrs (options.services.restic.backups.type.getSubOptions [ ]) (
                            [ "enable" ] ++ builtins.attrNames s3Defaults
                          );
                        };
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
        restic = {
          s3 = { };
        };
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
              value = job // (builtins.removeAttrs opts [ "restic" ]);
            }) restic
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
