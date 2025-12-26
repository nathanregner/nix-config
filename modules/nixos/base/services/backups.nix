{
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
    trivial
    types
    ;

  cfg = config.local.services.backup;

  baseOptions = options.services.restic.backups.type.getSubOptions [ ];

  mkDefault = default: mkOption { inherit default; };

  mkReadonly =
    default:
    mkOption {
      inherit default;
      readOnly = true;
    };

  targetOpts = [
    "exclude"
    "pruneOpts"
    "timerConfig"
  ];

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
        // lib.getAttrs (
          builtins.attrNames (lib.filterAttrs (_name: option: !(option.readOnly or false)) options)
          ++ targetOpts
        ) baseOptions;
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
          options =
            (lib.getAttrs (
              targetOpts
              ++ [
                "dynamicFilesFrom"
                "paths"
              ]
            ) baseOptions)
            // {
              root = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Root directory for backup command: https://forum.restic.net/t/skip-if-unchanged-usage/8636";
              };

              initialize = mkReadonly true;

              extraBackupArgs = mkReadonly [ "--skip-if-unchanged" ];

              pruneOpts = mkDefault [
                "--keep-within 7d"
                "--keep-within-daily 1m"
                "--keep-within-weekly 6m"
                "--keep-within-monthly 1y"
              ];

              targets = mkOption {
                default = {
                  s3 = { };
                };
                type = types.submodule {
                  options = {
                    s3 = mkTarget {
                      repository = mkReadonly "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${config.networking.hostName}/${name}";
                      passwordFile = mkReadonly config.sops.secrets.restic-password.path;
                      environmentFile = mkReadonly config.sops.secrets.restic-s3-env.path;
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
      in
      {
        sops.secrets = lib.mkIf (builtins.any (job: job.targets.s3.enable) (builtins.attrValues cfg.jobs)) {
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
