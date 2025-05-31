{
  local.users.minecraft = { };

  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 25565 ];
  };

  nginx.subdomain.minecraft."/" = {
    extraConfig = ''
      alias "/home/minecraft/www/";
      autoindex on;
    '';
  };

  # https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html
  systemd.services.nginx.serviceConfig = {
    ProtectHome = "tmpfs";
    BindReadOnlyPaths = "-/home/minecraft/www";
  };
}
