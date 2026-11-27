# Portable backup job definitions, shared by the nixos/darwin/homeManager adapters.
{ inputs, ... }:
let
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption types;
      backupLib = import ./_lib.nix { inherit lib; };

      cfg = config.local.services.backup;

      mkReadonly =
        type: default:
        mkOption {
          inherit type default;
          readOnly = true;
        };

      mkTarget =
        {
          repository,
          environmentFile ? null,
          interval,
        }:
        mkOption {
          default = { };
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
              };
              interval = mkOption {
                type = backupLib.intervalType;
                default = interval;
                description = "How often to back up to this target. Overridden by the job's `interval`.";
              };
              exclude = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Additional exclude patterns for this target.";
              };
              pruneOpts = mkOption {
                type = types.nullOr (types.listOf types.str);
                default = null;
                description = "Overrides the job's `pruneOpts` for this target.";
              };
              repository = mkReadonly types.str repository;
              environmentFile = mkReadonly (types.nullOr types.str) environmentFile;
            };
          };
        };

      jobModule =
        { name, config, ... }:
        {
          options = {
            paths = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
            dynamicFilesFrom = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Shell script whose output is a newline-separated list of paths to back up.";
            };
            exclude = mkOption {
              type = types.listOf types.str;
              default = [ ];
            };
            pruneOpts = mkOption {
              type = types.listOf types.str;
              default = [
                "--tag"
                "''"
                "--keep-within 7d"
                "--keep-within-daily 1m"
                "--keep-within-weekly 6m"
                "--keep-within-monthly 1y"
              ];
            };
            interval = mkOption {
              type = types.nullOr backupLib.intervalType;
              default = null;
              example = "1h";
              description = "How often to back up, for all targets. Defaults to each target's `interval`.";
            };
            root = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Root directory for backup command: https://forum.restic.net/t/skip-if-unchanged-usage/8636";
            };
            targets = mkOption {
              default = { };
              type = types.submodule {
                options = {
                  server = mkTarget {
                    repository = "rest:http://sagittarius:${toString inputs.self.globals.services.restic-server.port}/${cfg.repoPrefix}/${name}";
                    environmentFile = config'.sops.templates.restic-server-env.path;
                    interval = "6h";
                  };
                  google-drive = mkTarget {
                    repository = "rclone:google_drive:restic/${cfg.repoPrefix}/${name}";
                    interval = "1d";
                  };
                };
              };
            };
          };

          config = lib.mkIf (config.root != null) {
            paths = lib.mkDefault [ "." ];
          };
        };

      config' = config;

      hasTarget = name: builtins.any (job: job.targets.${name}.enable) (builtins.attrValues cfg.jobs);
    in
    {
      options.local.services.backup = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };

        hostName = mkOption {
          type = types.str;
          description = "Host name used for repository paths and rest-server authentication.";
        };

        repoPrefix = mkOption {
          type = types.str;
          internal = true;
          description = "Repository path prefix; must start with `hostName` for rest-server private repos.";
        };

        package = mkOption {
          type = types.package;
          default = pkgs.restic;
        };

        # TODO: error if no files
        jobs = mkOption {
          default = { };
          type = types.attrsOf (types.submodule jobModule);
        };

        backups = mkOption {
          internal = true;
          readOnly = true;
          description = "Flattened `<job>-<target>` backups consumed by the platform adapters.";
          default = lib.concatMapAttrs (
            jobName: job:
            lib.mapAttrs' (
              targetName: target:
              lib.nameValuePair "${jobName}-${targetName}" {
                inherit (job) root paths dynamicFilesFrom;
                inherit (target) repository environmentFile;
                exclude = job.exclude ++ target.exclude;
                pruneOpts = if target.pruneOpts != null then target.pruneOpts else job.pruneOpts;
                interval = if job.interval != null then job.interval else target.interval;
                passwordFile = config.sops.secrets.restic-password.path;
              }
            ) (lib.filterAttrs (_: target: target.enable) job.targets)
          ) cfg.jobs;
        };
      };

      config = lib.mkMerge [
        {
          assertions = lib.mapAttrsToList (name: job: {
            assertion =
              !(
                job.root != null && (job.paths != [ "." ] || job.dynamicFilesFrom != null)
                || (job.paths != [ ] && job.dynamicFilesFrom != null)
                || (job.dynamicFilesFrom == null && job.paths == [ ])
              );
            message = ''
              local.services.backup.jobs.${name}: exactly one of root, paths, or dynamicFilesFrom should be set:
                  root = ${toString job.root}
                  paths = [ ${lib.concatStringsSep ", " job.paths} ]
                  dynamicFilesFrom = ${toString job.dynamicFilesFrom}
            '';
          }) cfg.jobs;
        }

        (lib.mkIf (cfg.enable && cfg.backups != { }) {
          sops.secrets = {
            restic-password.key = "restic/password";
          }
          // lib.optionalAttrs (hasTarget "server") {
            restic-server-password.key = "restic/server/password";
          };

          sops.templates = lib.optionalAttrs (hasTarget "server") {
            restic-server-env.content = ''
              RESTIC_REST_USERNAME=${cfg.hostName}
              RESTIC_REST_PASSWORD=${config.sops.placeholder.restic-server-password}
            '';
          };
        })
      ];
    };
in
{
  flake.modules.nixos.backup = module;
  flake.modules.darwin.backup = module;
  flake.modules.homeManager.backup = module;
}
