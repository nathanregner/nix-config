{ lib, ... }:
{
  local.users.factorio = { };

  networking.firewall = {
    allowedUDPPorts = [ 34197 ];
  };

  nginx.subdomain.factorio."/" = {
    proxyPass = "http://127.0.0.1:65001/";
  };

  local.services.backup.jobs.factorio = {
    root = "/home/factorio";
    timerConfig = {
      OnCalendar = lib.mkForce "hourly";
      Persistent = true;
    };
    pruneOpts = lib.mkForce [
      "--tag"
      "''"
      "--keep-within 1d"
      "--keep-within-daily 7d"
    ];
  };
}
