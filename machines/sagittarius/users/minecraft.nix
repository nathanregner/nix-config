{ lib, ... }:
{
  local.users.minecraft = { };

  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 25565 ];
  };

  nginx.subdomain.minecraft."/" = {
    proxyPass = "http://127.0.0.1:65000/";
  };

  local.services.backup.jobs.minecraft = {
    timerConfig = {
      OnCalendar = lib.mkForce "hourly";
      Persistent = true;
    };
    # TODO: this option should not merge
    pruneOpts = lib.mkForce [
      "--tag"
      "''"
      "--keep-within 1d"
      "--keep-within-daily 1m"
    ];
  };

}
