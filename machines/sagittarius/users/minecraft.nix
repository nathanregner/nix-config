{ lib, ... }:
{
  local.users.minecraft = { };

  # TODO: cleanup
  services.restic.backups.minecraft-s3 = {
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

  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 25565 ];
  };

  nginx.subdomain.minecraft."/" = {
    proxyPass = "http://127.0.0.1:65000/";
  };
}
