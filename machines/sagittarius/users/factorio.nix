{ lib, ... }:
{
  local.users.factorio = { };

  networking.firewall = {
    allowedUDPPorts = [ 34197 ];
  };
  nginx.subdomain.factorio = {
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:65001/";
      };
    };
  };

  local.services.backup.jobs.factorio = {
    root = "/home/factorio";
    interval = "1h";
    pruneOpts = lib.mkForce [
      "--tag"
      "''"
      "--keep-within 1d"
      "--keep-within-daily 7d"
    ];
  };
}
