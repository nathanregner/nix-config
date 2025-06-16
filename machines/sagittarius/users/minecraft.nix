{
  local.users.minecraft = { };

  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 25565 ];
  };

  nginx.subdomain.minecraft."/" = {
    proxyPass = "http://127.0.0.1:65000/";
  };
}
