{
  self,
  options,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mapAttrsToList
    mkOption
    optionalAttrs
    trivial
    types
    ;

  cfg = config.local.services.backup;

  baseOptions = options.services.restic.backups.type.getSubOptions [ ];

  mkDefault =
    default: option:
    option
    // lib.traceValSeq {
      inherit default;
    };

  mkReadonly =
    default: option:
    option
    // {
      inherit default;
      readOnly = true;
    };

  targetOptions = {
    inherit (baseOptions)
      exclude
      pruneOpts
      timerConfig
      ;
  };

  mkOverrides = overrides: builtins.mapAttrs (name: override: override baseOptions.${name}) overrides;

  mkTarget =
    base: overrides:
    mkOption {
      type = types.submodule {
        options =
          targetOptions
          // mkOverrides overrides
          // {
            enable = mkOption {
              type = types.bool;
              default = true;
            };
          };
      };
    };

in
{
  options.local.services.backup.enable = mkOption {
    default = !(options.virtualisation ? qemu);
  };

  # TODO: error if no files
  options.local.services.backup.jobs = mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        base@{ name, ... }:
        {
          options = {
            inherit (baseOptions) dynamicFilesFrom paths;
          }
          // targetOptions
          // mkOverrides {
            initialize = mkReadonly true;
            passwordFile = mkReadonly config.sops.secrets.restic-password.path;
            extraBackupArgs = mkReadonly [ "--skip-if-unchanged" ];
            pruneOpts = mkDefault [
              "--keep-within 7d"
              "--keep-within-daily 1m"
              "--keep-within-weekly 6m"
              "--keep-within-monthly 1y"
            ];
          }
          // {
            root = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Root directory for backup command: https://forum.restic.net/t/skip-if-unchanged-usage/8636";
            };

            targets = mkOption {
              default = {
                s3 = { };
                server = { };
              };
              type = types.submodule {
                options = {
                  s3 = mkTarget base {
                    repository = mkReadonly "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${config.networking.hostName}/${name}";
                    environmentFile = mkReadonly config.sops.secrets.restic-s3-env.path;
                    timerConfig = mkDefault {
                      OnCalendar = "daily";
                      Persistent = true;
                    };
                  };
                  server = mkTarget base {
                    repository = mkReadonly "rest:http://sagittarius:${toString self.globals.services.restic-server.port}/${config.networking.hostName}/${name}";
                    environmentFile = mkReadonly config.sops.templates.restic-server-env.path;
                    timerConfig = mkDefault {
                      OnCalendar = "0/6:00:00";
                      Persistent = true;
                    };
                  };
                };
              };
            };
          };

          config = lib.mkIf (base.config.root != null) {
            paths = lib.mkDefault [ "." ];
          };
        }
      )
    );
  };

  config = lib.mkMerge [
    {
      # https://discourse.nixos.org/t/psa-pinning-users-uid-is-important-when-reinstalling-nixos-restoring-backups/21819
      local.services.backup.jobs.nixos = {
        root = "/var/lib/nixos";
      };

      assertions = lib.mapAttrsToList (name: job: {
        assertion =
          !(
            job.root != null && (job.paths != [ "." ] || job.dynamicFilesFrom != null)
            || (job.paths != [ ] && job.dynamicFilesFrom != null)
            || (job.dynamicFilesFrom == null && job.paths == [ ])
          );
        message = ''
          local.services.backup.jobs.${name}: exactly one of root, paths, or dynamicFilesFrom should be set:
              root = ${builtins.toString job.root}
              paths = [ ${lib.concatStringsSep ", " job.paths} ]
              dynamicFilesFrom = ${builtins.toString job.dynamicFilesFrom}
        '';
      }) cfg.jobs;
    }
    (lib.mkIf cfg.enable (
      let
        backups = trivial.pipe cfg.jobs [
          (mapAttrsToList (
            name: job:
            mapAttrs' (type: target: {
              name = "${name}-${type}";
              value = {
                inherit (job) root;
                resticConfig =
                  builtins.removeAttrs target [ "enable" ]
                  // builtins.removeAttrs job [
                    "root"
                    "targets"
                  ];
              };
            }) (filterAttrs (_: target: target.enable) job.targets)
          ))
          lib.mergeAttrsList
        ];
        hasTarget = name: builtins.any (job: job.targets.${name}.enable) (builtins.attrValues cfg.jobs);
      in
      {
        sops.secrets = {
          restic-password = {
            key = "restic_password";
            group = "restic";
            mode = "0440";
          };
        }
        // optionalAttrs (hasTarget "s3") {
          restic-s3-env = {
            key = "restic/s3_env";
            group = "restic";
            mode = "0440";
          };
        }
        // optionalAttrs (hasTarget "server") {
          restic-server-password = {
            key = "restic/server/password";
            group = "restic";
            mode = "0440";
          };
        };

        sops.templates = optionalAttrs (hasTarget "server") {
          restic-server-env = {
            content = ''
              RESTIC_REST_USERNAME=${config.networking.hostName}
              RESTIC_REST_PASSWORD=${config.sops.placeholder.restic-server-password}
            '';
            owner = "restic";
          };
        };

        users.groups.restic = {
        };

        services.restic.backups = lib.mapAttrs (_name: job: job.resticConfig) backups;

        systemd.services = lib.mapAttrs' (
          name: job:
          lib.nameValuePair "restic-backups-${name}" {
            serviceConfig.WorkingDirectory = lib.mkIf (job.root != null) job.root;
          }
        ) backups;
      }
    ))
  ];
}
