{
  config,
  pkgs,
  lib,
  ...
}:
let
  rootDir = "/var/lib/octoprint";
  restartPath = "${rootDir}/restart";
in
{
  nixpkgs.overlays = [
    (_final: prev: { ffmpeg = prev.ffmpeg.override { ffmpegVariant = "headless"; }; })
  ];

  services.octoprint = {
    enable = true;
    openFirewall = true;
    stateDir = "${rootDir}/live";
    port = 80;
    extraConfig = {
      server = {
        commands = {
          serverRestartCommand = "touch ${restartPath}";
        };
        firstRun = false;
        onlineCheck.enabled = false;
        pluginBlacklist.enabled = false;
      };
      # https://docs.octoprint.org/en/master/configuration/config_yaml.html#access-control
      accessControl = {
        autologinLocal = true;
        autologinAs = "root";
        localNetworks = [
          "127.0.0.0/8"
          "192.168.0.0/16"
          "100.0.0.0/8"
        ];
      };
      serial.autoconnect = true;
      plugins.tracking.enable = false;
      printerProfiles.default = "ender-s3-s1";
    };
  };

  environment.systemPackages = [ pkgs.octoprint ];

  systemd.services.octoprint = {
    # allow octoprint to bind to port 80
    serviceConfig = {
      AmbientCapabilities = "cap_net_bind_service";
      CapabilityBoundingSet = "cap_net_bind_service";
    };
    preStart =
      let
        inherit (config.services.octoprint) stateDir;
        cfgUpdate = pkgs.writeText "octoprint-users.yaml" (
          builtins.toJSON {
            _version = 2;
            root = {
              active = true;
              apikey = null;
              groups = [
                "users"
                "admins"
              ];
              password = "$argon2id$v=19$m=65536,t=3,p=4$3FtLCWGM8Z5TCmHsXQuh9A$H5rEbKFN5O1zhn/E6q288KkDIOq4yTMTYyz4SsLPshQ";
              permissions = [ ];
              roles = [
                "user"
                "admin"
              ];
              settings = { };
            };
          }
        );
      in
      ''
        if [ -e "${stateDir}/users.yaml" ]; then
          ${pkgs.yaml-merge}/bin/yaml-merge "${stateDir}/users.yaml" "${cfgUpdate}" > "${stateDir}/users.yaml.tmp"
          mv "${stateDir}/users.yaml.tmp" "${stateDir}/users.yaml"
        else
          cp "${cfgUpdate}" "${stateDir}/users.yaml"
          chmod 600 "${stateDir}/users.yaml"
        fi
      '';
  };
  # give permission to move stateDir to stateDir.bkp when restoring backups
  systemd.tmpfiles.rules =
    [ "d '${rootDir}' - ${config.services.octoprint.user} ${config.services.octoprint.group} - -" ]
    ++ (lib.mapAttrsToList (
      path: _:
      "L+ ${config.services.octoprint.stateDir}/printerProfiles/${path} - - - - ${./profiles + ("/" + path)}"
    ) (builtins.readDir ./profiles));

  systemd.paths.octoprint-watcher = {
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      User = config.services.octoprint.user;
      Group = config.services.octoprint.group;
    };
    pathConfig = {
      PathChanged = [ restartPath ];
      Unit = "octoprint-restarter.service";
    };
  };

  systemd.services.octoprint-restarter = {
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
    };
    script = "systemctl restart octoprint.service";
  };
}
