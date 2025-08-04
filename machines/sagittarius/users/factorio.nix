{
  local.users.factorio = { };

  networking.firewall = {
    allowedUDPPorts = [ 34197 ];
  };

  local.services.backup.paths.factorio = {
    paths = [ "/home/factorio" ];
    restic = {
      s3 = { };
    };
  };
}
