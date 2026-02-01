{
  flake.modules.homeManager.wl-clipboard-sync =
    { pkgs, ... }:
    let
      package = pkgs.unstable.wl-clipboard;
    in
    {
      home.packages = [ package ];

      systemd.user.services.wl-clipboard-sync = {
        Unit = {
          Description = "Keep selection buffer and clipboard in sync";
        };
        Service = {
          ExecStart = pkgs.writeShellScript "wl-clipboard-sync" ''
            ${package}/bin/wl-paste -p -w '${package}/bin/wl-copy'
          '';
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
