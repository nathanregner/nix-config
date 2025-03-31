# source: https://github.com/AtaraxiaSjel/nur/blob/master/modules/rustic.nix
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  # Type for a valid systemd unit option. Needed for correctly passing "timerConfig" to "systemd.timers"
  inherit (utils.systemdUtils.unitOptions) unitOption;
  settingsFormat = pkgs.formats.toml { };
in
{
  options.services.rustic.backups = lib.mkOption {
    description = lib.mdDoc ''
      Periodic backups to create with Rustic.
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        { ... }:
        {
          options = {
            settings = lib.mkOption {
              type = settingsFormat.type;
              default = { };
              description = lib.mdDoc "";
            };

            passwordFile = lib.mkOption {
              type = lib.types.str;
              description = ''
                Read the repository password from a file.
              '';
              example = "/etc/nixos/restic-password";
            };

            environmentFile = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                file containing the credentials to access the repository, in the
                format of an EnvironmentFile as described by {manpage}`systemd.exec(5)`
              '';
            };

            extraEnvironment = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              example = lib.literalExpression ''
                {
                  http_proxy = "http://server:12345";
                }
              '';
              description = lib.mdDoc "Environment variables to pass to rustic.";
            };

            rcloneOptions = lib.mkOption {
              type =
                with lib.types;
                nullOr (
                  attrsOf (oneOf [
                    str
                    bool
                  ])
                );
              default = null;
              description = lib.mdDoc ''
                Options to pass to rclone to control its behavior.
                See <https://rclone.org/docs/#options> for
                available options. When specifying option names, strip the
                leading `--`. To set a flag such as
                `--drive-use-trash`, which does not take a value,
                set the value to the Boolean `true`.
              '';
              example = {
                bwlimit = "10M";
                drive-use-trash = "true";
              };
            };

            rcloneConfigFile = lib.mkOption {
              type = with lib.types; nullOr path;
              default = null;
              description = lib.mdDoc ''
                Path to the file containing rclone configuration. This file
                must contain configuration for the remote specified in this backup
                set and also must be readable by root. Options set in
                `rcloneConfig` will override those set in this
                file.
              '';
            };

            repository = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = ''
                repository to backup to.
              '';
              example = "sftp:backup@192.168.1.100:/backups/name";
            };

            repositoryFile = lib.mkOption {
              type = with lib.types; nullOr path;
              default = null;
              description = ''
                Path to the file containing the repository location to backup to.
              '';
            };

            timerConfig = lib.mkOption {
              type = lib.types.attrsOf unitOption;
              default = {
                OnCalendar = "daily";
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

            user = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = lib.mdDoc ''
                As which user the backup should run.
              '';
              example = "postgresql";
            };

            extraBackupArgs = lib.mkOption {
              type = with lib.types; listOf str;
              default = [ ];
              description = lib.mdDoc ''
                Extra arguments passed to rustic backup.
              '';
              example = [ "--exclude-file=/etc/nixos/rustic-ignore" ];
            };

            extraOptions = lib.mkOption {
              type = with lib.types; listOf str;
              default = [ ];
              description = lib.mdDoc ''
                Extra extended options to be passed to the rustic --option flag.
              '';
              example = [ "sftp.command='ssh backup@192.168.1.100 -i /home/user/.ssh/id_rsa -s sftp'" ];
            };

            backup = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = lib.mdDoc ''
                Start backup.
              '';
            };

            prune = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = lib.mdDoc ''
                Start prune.
              '';
            };

            initialize = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = lib.mdDoc ''
                Create the repository if it doesn't exist.
              '';
            };

            initializeOpts = lib.mkOption {
              type = with lib.types; listOf str;
              default = [ ];
              description = lib.mdDoc ''
                A list of options for 'rustic init'.
              '';
              example = [ "--set-version 2" ];
            };

            checkOpts = lib.mkOption {
              type = with lib.types; listOf str;
              default = [ ];
              description = lib.mdDoc ''
                A list of options for 'rustic check', which is run after
                pruning.
              '';
              example = [ "--with-cache" ];
            };

            pruneOpts = lib.mkOption {
              type = with lib.types; listOf str;
              default = [ ];
              description = lib.mdDoc ''
                A list of options for 'rustic prune', which is run before
                pruning.
              '';
              example = [ "--repack-cacheable-only=false" ];
            };

            backupCommandPrefix = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = lib.mdDoc ''
                Prefix for backup command.
              '';
            };

            backupCommandSuffix = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = lib.mdDoc ''
                Suffix for backup command.
              '';
            };

            backupPrepareCommand = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = lib.mdDoc ''
                A script that must run before starting the backup process.
              '';
            };

            backupCleanupCommand = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = lib.mdDoc ''
                A script that must run after finishing the backup process.
              '';
            };

            package = lib.mkPackageOption "pkgs" "rustic-rs" { };

            createWrapper = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Whether to generate and add a script to the system path, that has the same environment variables set
                as the systemd service. This can be used to e.g. mount snapshots or perform other opterations, without
                having to manually specify most options.
              '';
            };
          };
        }
      )
    );
    default = { };
  };

  config = {
    systemd.services = lib.mapAttrs' (
      name: backup:
      let
        profile = settingsFormat.generate "${name}.toml" backup.settings;
        extraOptions = lib.concatMapStrings (arg: " -o ${arg}") backup.extraOptions;
        rusticCmd = "${backup.package}/bin/rustic -P ${lib.strings.removeSuffix ".toml" profile}${extraOptions}";
        # Helper functions for rclone remotes
        rcloneAttrToOpt = v: "RCLONE_" + lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] v);
        toRcloneVal = v: if lib.isBool v then lib.boolToString v else v;
      in
      lib.nameValuePair "rustic-backups-${name}" (
        {
          environment =
            backup.extraEnvironment
            // {
              # not %C, because that wouldn't work in the wrapper script
              RUSTIC_CACHE_DIR = "/var/cache/rustic-backups-${name}";
              RUSTIC_PASSWORD_FILE = backup.passwordFile;
              RESTIC_REPOSITORY = backup.repository;
              RESTIC_REPOSITORY_FILE = backup.repositoryFile;
            }
            // lib.optionalAttrs (backup.rcloneOptions != null) (
              lib.mapAttrs' (
                name: value: lib.nameValuePair (rcloneAttrToOpt name) (toRcloneVal value)
              ) backup.rcloneOptions
            )
            // lib.optionalAttrs (backup.rcloneConfigFile != null) {
              RCLONE_CONFIG = backup.rcloneConfigFile;
            };
          path = [
            config.programs.ssh.package
            pkgs.rclone
          ];
          restartIfChanged = false;
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          script = ''
            ${lib.optionalString (backup.backup) ''
              ${backup.backupCommandPrefix} ${rusticCmd} backup ${lib.concatStringsSep " " backup.extraBackupArgs} ${backup.backupCommandSuffix}
            ''}
            ${lib.optionalString (backup.prune) ''
              ${rusticCmd} forget --prune ${lib.concatStringsSep " " backup.pruneOpts}
              ${rusticCmd} check ${lib.concatStringsSep " " backup.checkOpts}
            ''}
          '';
          serviceConfig =
            {
              Type = "oneshot";
              User = backup.user;
              RuntimeDirectory = "rustic-backups-${name}";
              CacheDirectory = "rustic-backups-${name}";
              CacheDirectoryMode = "0700";
              PrivateTmp = true;
            }
            // lib.optionalAttrs (backup.environmentFile != null) { EnvironmentFile = backup.environmentFile; };
        }
        // lib.optionalAttrs (backup.initialize || backup.backupPrepareCommand != null) {
          preStart = ''
            ${lib.optionalString (backup.backupPrepareCommand != null) ''
              ${pkgs.writeScript "backupPrepareCommand" backup.backupPrepareCommand}
            ''}
            ${lib.optionalString (backup.initialize) ''
              ${rusticCmd} init ${lib.concatStringsSep " " backup.initializeOpts} || true
            ''}
          '';
        }
        // lib.optionalAttrs (backup.backupCleanupCommand != null) {
          postStop = ''
            ${lib.optionalString (backup.backupCleanupCommand != null) ''
              ${pkgs.writeScript "backupCleanupCommand" backup.backupCleanupCommand}
            ''}
          '';
        }
      )
    ) config.services.rustic.backups;
    systemd.timers = lib.mapAttrs' (
      name: backup:
      lib.nameValuePair "rustic-backups-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = backup.timerConfig;
      }
    ) (lib.filterAttrs (_: backup: backup.timerConfig != null) config.services.restic.backups);

    # generate wrapper scripts, as described in the createWrapper option
    environment.systemPackages = lib.mapAttrsToList (
      name: backup:
      let
        profile = settingsFormat.generate "${name}.toml" backup.settings;
        extraOptions = lib.concatMapStrings (arg: " -o ${arg}") backup.extraOptions;
        rusticCmd = "${backup.package}/bin/rustic -P ${lib.strings.removeSuffix ".toml" profile}${extraOptions}";
      in
      pkgs.writeShellScriptBin "rustic-${name}" ''
        set -a  # automatically export variables
        ${lib.optionalString (backup.environmentFile != null) "source ${backup.environmentFile}"}
        # set same environment variables as the systemd service
        ${lib.pipe config.systemd.services."rustic-backups-${name}".environment [
          (lib.filterAttrs (n: v: v != null && n != "PATH"))
          (lib.mapAttrsToList (n: v: "${n}=${v}"))
          (lib.concatStringsSep "\n")
        ]}
        PATH=${config.systemd.services."restic-backups-${name}".environment.PATH}:$PATH

        exec ${rusticCmd} $@
      ''
    ) (lib.filterAttrs (_: v: v.createWrapper) config.services.rustic.backups);
  };
}
