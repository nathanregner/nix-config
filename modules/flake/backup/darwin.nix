# nix-darwin adapter: nix-darwin has no restic module, so run our own script from launchd daemons
{
  flake.modules.darwin.backup =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      backupLib = import ./_lib.nix { inherit lib; };
      cfg = config.local.services.backup;
      wrappers = lib.mapAttrs (name: backupLib.mkWrapper pkgs cfg.package name) cfg.backups;
    in
    {
      config = lib.mkMerge [
        {
          local.services.backup = {
            hostName = lib.mkIf (config.networking.hostName != null) (lib.mkDefault config.networking.hostName);
            repoPrefix = cfg.hostName;
          };
        }

        (lib.mkIf (cfg.enable && cfg.backups != { }) {
          launchd.daemons = lib.mapAttrs' (
            name: backup:
            lib.nameValuePair "restic-backups-${name}" {
              serviceConfig = {
                ProgramArguments = [
                  (lib.getExe (backupLib.mkRunner pkgs wrappers.${name} name backup))
                ];
                StartInterval = backupLib.toSeconds backup.interval;
                RunAtLoad = false;
                StandardOutPath = "/var/log/restic-backups-${name}.log";
                StandardErrorPath = "/var/log/restic-backups-${name}.log";
              };
            }
          ) cfg.backups;

          environment.systemPackages =
            lib.attrValues wrappers
            ++ lib.mapAttrsToList (name: _: backupLib.mkCompletions pkgs name cfg.package) cfg.backups;
        })
      ];
    };
}
