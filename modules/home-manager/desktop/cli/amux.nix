{ pkgs, lib, ... }:
let
  amux = pkgs.local.amux;
  # tmux must be on PATH so the daemon can drive `refresh-client`.
  daemonPath = lib.makeBinPath [
    amux
    pkgs.tmux
  ];
in
{
  programs.claude-code.merged-hooks = lib.genAttrs [
    "Notification"
    "PermissionRequest"
    "PostToolUse"
    "PostToolUseFailure"
    "Stop"
    "UserPromptSubmit"
  ] (_: [ { command = "amux hook"; } ]);

  home.packages = [
    amux
  ];

  # Watch the status file and refresh the tmux status bar. Sandboxed agents
  # write the status file from inside a container and can't reach the host tmux
  # server, so this host-side daemon is what makes their updates visible.
  launchd.agents.amux-daemon = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${amux}/bin/amux"
        "daemon"
      ];
      EnvironmentVariables.PATH = daemonPath;
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  systemd.user.services.amux-daemon = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "amux tmux status-line daemon";
    };
    Service = {
      Environment = [ "PATH=${daemonPath}" ];
      ExecStart = "${amux}/bin/amux daemon";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
