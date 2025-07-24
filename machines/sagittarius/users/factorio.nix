{
  local.users.factorio = { };

  networking.firewall = {
    allowedUDPPorts = [ 34197 ];
  };

  local.services.backup.restic.factorio = {
    paths = [ "/home/factorio" ];
    s3 = { };
  };
}
