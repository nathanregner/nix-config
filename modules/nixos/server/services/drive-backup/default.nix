{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  user = "drive-backup";
  group = "wheel";
  cfg = config.services.nregner.backup.drive;
  cfgFile = "${config.users.users.drive-backup.home}/rclone.conf";
  rclone = pkgs.unstable.rclone;
in
{
  options.services.nregner.backup.drive = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    dataDir = mkOption {
      type = types.path;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.drive-backup-client-secret = {
      key = "drive/client_secret";
      sopsFile = ./secrets.yaml;
      owner = user;
    };

    sops.templates.drive-backup-env = {
      content = ''
        RCLONE_CONFIG_DRIVE_CLIENT_SECRET=${config.sops.placeholder.drive-backup-client-secret}
      '';
      owner = user;
    };

    systemd.tmpfiles.rules = [
      # cfgFile must be mutable; contains auth/refresh token
      "f '${cfgFile}' 0660 ${user} ${group} - -"
      "d '${cfg.dataDir}' 0660 ${user} ${group} - -"
    ];

    systemd.timers.drive-backup = {
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "daily";
      };
    };

    systemd.services.drive-backup = {
      after = [ "network.target" ];
      requires = [ "network.target" ];
      serviceConfig = {
        ExecStart = ''
          ${rclone}/bin/rclone --config ${cfgFile} sync --fast-list --dry-run --max-transfer=32 -vvvv drive:/ ${cfg.dataDir}
        '';
        User = user;
        Group = user;
        EnvironmentFile = config.sops.templates.drive-backup-env.path;
      };
      environment = {
        RCLONE_CONFIG_DRIVE_TYPE = "drive";
        RCLONE_CONFIG_DRIVE_CLIENT_ID = "748757753695-58o2thpdor0p76e0e3chbfpf0k8mlf88.apps.googleusercontent.com";
        RCLONE_CONFIG_DRIVE_SCOPE = "drive.readonly";
      };
    };

    users.users.${user} = {
      group = user;
      home = "/var/lib/drive-backup";
      createHome = true;
      isSystemUser = true;
      description = "Google Drive rclone user";
    };

    users.groups.${user} = {
      gid = null;
    };

    environment.systemPackages = [
      rclone
    ];
  };
}
