{ config, ... }:
let
  rootDir = "/var/lib/octoprint";
  restartPath = "${rootDir}/restart";
in {
  nixpkgs.overlays = [
    (final: prev: {
      ffmpeg = prev.ffmpeg.override { ffmpegVariant = "headless"; };
    })
  ];

  services.octoprint = {
    enable = true;
    openFirewall = true;
    stateDir = "${rootDir}/live";
    port = 80;
    extraConfig = {
      server = {
        commands = { serverRestartCommand = "touch ${restartPath}"; };
      };
    };
  };

  # allow octoprint to bind to port 80
  systemd.services.octoprint.serviceConfig = {
    AmbientCapabilities = "cap_net_bind_service";
    CapabilityBoundingSet = "cap_net_bind_service";
  };

  # give permission to move stateDir to stateDir.bkp when restoring backups
  systemd.tmpfiles.rules = [
    "d '${rootDir}' - ${config.services.octoprint.user} ${config.services.octoprint.group} - -"
  ];

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
