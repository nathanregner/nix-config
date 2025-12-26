{
  local.users.factorio = { };

  networking.firewall = {
    allowedUDPPorts = [ 34197 ];
  };

  local.services.backup.jobs.factorio = {
    root = "/home/factorio";
    timerConfig.OnCalendar = "0/1:00:00";
  };
}
