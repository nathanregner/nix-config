# home-manager adapter:
# - Linux: upstream `services.restic.backups` + systemd user timers
# - darwin: upstream can't schedule (#7924), so run our own script from launchd agents
{
  flake.modules.homeManager.backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      backupLib = import ./_lib.nix { inherit lib; };
      cfg = config.local.services.backup;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      wrappers = lib.mapAttrs (name: backupLib.mkWrapper pkgs cfg.package name) cfg.backups;
    in
    {
      config = lib.mkMerge [
        {
          # rest-server private repos require the path to start with the (host) username
          local.services.backup.repoPrefix = "${cfg.hostName}/${config.home.username}";
        }

        (lib.mkIf (cfg.enable && cfg.backups != { } && !isDarwin) {
          services.restic = {
            enable = true;
            backups = lib.mapAttrs (_name: backup: {
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
              runCheck = false;
              extraBackupArgs = [ "--skip-if-unchanged" ];
              timerConfig = backupLib.toTimerConfig backup.interval;
            }) cfg.backups;
          };

          systemd.user.services = lib.mapAttrs' (
            name: backup:
            lib.nameValuePair "restic-backups-${name}" {
              Service.WorkingDirectory = lib.mkIf (backup.root != null) backup.root;
            }
          ) cfg.backups;

          home.packages = lib.mapAttrsToList (
            name: backup: backupLib.mkCompletions pkgs name backup.package
          ) config.services.restic.backups;
        })

        (lib.mkIf (cfg.enable && cfg.backups != { } && isDarwin) {
          launchd.agents = lib.mapAttrs' (
            name: backup:
            lib.nameValuePair "restic-backups-${name}" {
              enable = true;
              config = {
                ProgramArguments = [
                  (lib.getExe (backupLib.mkRunner pkgs wrappers.${name} name backup))
                ];
                StartInterval = backupLib.toSeconds backup.interval;
                RunAtLoad = false;
                StandardOutPath = "${config.xdg.stateHome}/restic-backups-${name}.log";
                StandardErrorPath = "${config.xdg.stateHome}/restic-backups-${name}.log";
              };
            }
          ) cfg.backups;

          home.packages =
            lib.attrValues wrappers
            ++ lib.mapAttrsToList (name: _: backupLib.mkCompletions pkgs name cfg.package) cfg.backups;
        })
      ];
    };
}
