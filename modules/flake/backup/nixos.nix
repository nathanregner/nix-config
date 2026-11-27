# NixOS adapter: upstream `services.restic.backups` + systemd timers
{
  flake.modules.nixos.backup =
    {
      config,
      options,
      lib,
      pkgs,
      ...
    }:
    let
      backupLib = import ./_lib.nix { inherit lib; };
      cfg = config.local.services.backup;
      hasServer = builtins.any (job: job.targets.server.enable) (builtins.attrValues cfg.jobs);
      restricted = {
        group = "restic";
        mode = "0440";
      };
    in
    {
      config = lib.mkMerge [
        {
          local.services.backup = {
            enable = lib.mkDefault (!(options.virtualisation ? qemu));
            hostName = lib.mkDefault config.networking.hostName;
            repoPrefix = cfg.hostName;

            # https://discourse.nixos.org/t/psa-pinning-users-uid-is-important-when-reinstalling-nixos-restoring-backups/21819
            jobs.nixos = {
              root = "/var/lib/nixos";
            };
          };
        }

        (lib.mkIf (cfg.enable && cfg.backups != { }) {
          sops.secrets = {
            restic-password = restricted;
            restic-server-password = lib.mkIf hasServer restricted;
          };
          sops.templates.restic-server-env = lib.mkIf hasServer restricted;

          users.groups.restic = { };

          services.restic.backups = lib.mapAttrs (_name: backup: {
            inherit (cfg) package;
            inherit (backup)
              paths
              dynamicFilesFrom
              exclude
              pruneOpts
              repository
              environmentFile
              passwordFile
              ;
            initialize = true;
            extraBackupArgs = [ "--skip-if-unchanged" ];
            timerConfig = backupLib.toTimerConfig backup.interval;
          }) cfg.backups;

          systemd.services = lib.mapAttrs' (
            name: backup:
            lib.nameValuePair "restic-backups-${name}" {
              serviceConfig.WorkingDirectory = lib.mkIf (backup.root != null) backup.root;
            }
          ) cfg.backups;

          environment.systemPackages =
            lib.optional (lib.any (b: lib.hasPrefix "rclone:" b.repository) (
              lib.attrValues cfg.backups
            )) pkgs.rclone
            ++ lib.mapAttrsToList (
              name: backup: backupLib.mkCompletions pkgs name backup.package
            ) config.services.restic.backups;
        })
      ];
    };
}
