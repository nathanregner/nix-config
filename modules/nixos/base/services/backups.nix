{
  self,
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.local.services.backup;

  baseOptions = options.services.restic.backups.type.getSubOptions [ ];

  mkDefault =
    default: option:
    option
    // {
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
              "--tag"
              "''"
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
                google-drive = { };
              };
              type = types.submodule {
                options = {
                  s3 = mkTarget base {
                    repository = mkReadonly "s3:s3.dualstack.us-west-2.amazonaws.com/nregner-restic/${config.networking.hostName}/${name}";
                    environmentFile = mkReadonly config.sops.secrets.restic-s3-env.path;
                    timerConfig = mkDefault {
                      OnCalendar = "daily";
                      RandomizedDelaySec = "10m";
                      Persistent = true;
                    };
                  };
                  server = mkTarget base {
                    repository = mkReadonly "rest:http://sagittarius:${toString self.globals.services.restic-server.port}/${config.networking.hostName}/${name}";
                    environmentFile = mkReadonly config.sops.templates.restic-server-env.path;
                    timerConfig = mkDefault {
                      OnCalendar = "0/6:00:00";
                      RandomizedDelaySec = "10m";
                      Persistent = true;
                    };
                  };
                  google-drive = mkTarget base {
                    repository = mkReadonly "rclone:google_drive:restic/${config.networking.hostName}/${name}";
                    timerConfig = mkDefault {
                      OnCalendar = "daily";
                      RandomizedDelaySec = "10m";
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
              root = ${toString job.root}
              paths = [ ${lib.concatStringsSep ", " job.paths} ]
              dynamicFilesFrom = ${toString job.dynamicFilesFrom}
        '';
      }) cfg.jobs;
    }
    (lib.mkIf cfg.enable (
      let
        backups = lib.mergeAttrsList (
          lib.mapAttrsToList (
            name: job:
            lib.mapAttrs' (type: target: {
              name = "${name}-${type}";
              value = {
                inherit (job) root;
                resticConfig =
                  removeAttrs target [ "enable" ]
                  // removeAttrs job [
                    "root"
                    "targets"
                  ];
              };
            }) (lib.filterAttrs (_: target: target.enable) job.targets)
          ) cfg.jobs
        );
        hasTarget = name: builtins.any (job: job.targets.${name}.enable) (builtins.attrValues cfg.jobs);
        pushgatewayUrl = "http://sagittarius:${toString self.globals.services.prometheus.pushgateway.port}";
        metricsScripts = lib.mapAttrs (
          name: _job:
          let
            # Find the restic wrapper created by the nixos restic module
            resticWrapper =
              lib.findFirst (pkg: pkg.name == "restic-${name}")
                (throw "restic-${name} wrapper not found in environment.systemPackages")
                config.environment.systemPackages;
          in
          pkgs.writeShellApplication {
            name = "restic-backups-${name}-metrics";
            runtimeInputs = [
              resticWrapper
              pkgs.jq
              pkgs.coreutils
              pkgs.curl
            ];
            text = ''
              if [ "$SERVICE_RESULT" = "success" ]; then
                success=1
              else
                success=0
              fi
              timestamp=$(date +%s)

              stats_start=$(date +%s%3N)
              stats=$(restic-${name} stats --json 2>/dev/null) && stats_ok=1 || stats_ok=0
              stats_end=$(date +%s%3N)
              scrape_ms=$(( stats_end - stats_start ))
              scrape_duration=$(printf '%d.%03d' $(( scrape_ms / 1000 )) $(( scrape_ms % 1000 )))

              {
                cat <<METRICS
              # HELP restic_backup_success 1 if the last backup succeeded, 0 otherwise
              restic_backup_success $success
              # HELP restic_backup_last_run_timestamp_seconds Unix timestamp of the last backup run
              restic_backup_last_run_timestamp_seconds $timestamp
              # HELP restic_scrape_duration_seconds Time taken to gather repository stats
              restic_scrape_duration_seconds $scrape_duration
              METRICS
                if [ "$stats_ok" = "1" ]; then
                  jq -r 'to_entries[] | "restic_\(.key) \(.value)"' <<< "$stats"
                fi
              } | curl --silent --show-error --data-binary @- \
                "${pushgatewayUrl}/metrics/job/restic_backup/instance/${config.networking.hostName}/${name}" \
                || true
            '';
          }
        ) backups;
      in
      {
        sops.secrets = {
          restic-password = {
            key = "restic_password";
            group = "restic";
            mode = "0440";
          };
        }
        // lib.optionalAttrs (hasTarget "s3") {
          restic-s3-env = {
            key = "restic/s3_env";
            group = "restic";
            mode = "0440";
          };
        }
        // lib.optionalAttrs (hasTarget "server") {
          restic-server-password = {
            key = "restic/server/password";
            group = "restic";
            mode = "0440";
          };
        };

        sops.templates = lib.optionalAttrs (hasTarget "server") {
          restic-server-env = {
            content = ''
              RESTIC_REST_USERNAME=${config.networking.hostName}
              RESTIC_REST_PASSWORD=${config.sops.placeholder.restic-server-password}
            '';
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
            serviceConfig = {
              WorkingDirectory = lib.mkIf (job.root != null) job.root;
            };
            postStop = lib.mkAfter ''
              ${metricsScripts.${name}}/bin/restic-backups-${name}-metrics
            '';
          }
        ) backups;

        environment.systemPackages =
          (lib.optionals (hasTarget "google-drive") [ pkgs.rclone ])
          ++ lib.mapAttrsToList (
            name: backup:
            pkgs.runCommand "restic-${name}-completions" { nativeBuildInputs = [ pkgs.installShellFiles ]; } ''
              cat > bash-completion <<EOF
              if ! declare -F _restic >/dev/null 2>&1; then
                source ${backup.package}/share/bash-completion/completions/restic
              fi
              complete -F _restic restic-${name}
              EOF

              cat > zsh-completion <<EOF
              #compdef restic-${name}
              if (( ! \$+functions[_restic] )); then
                fpath+=(${backup.package}/share/zsh/site-functions)
                autoload -Uz _restic
              fi
              _restic "\$@"
              EOF

              cat > fish-completion <<EOF
              if not functions -q __fish_restic_no_subcommand
                test -f ${backup.package}/share/fish/vendor_completions.d/restic.fish && source ${backup.package}/share/fish/vendor_completions.d/restic.fish
              end
              complete -c restic-${name} -w restic
              EOF

              installShellCompletion --cmd restic-${name} \
                --bash bash-completion \
                --zsh zsh-completion \
                --fish fish-completion
            ''
          ) config.services.restic.backups
          ++ lib.attrValues metricsScripts;
      }
    ))
  ];
}
