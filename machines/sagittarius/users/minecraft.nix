{ self, lib, ... }:
{
  users.users.minecraft = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
    linger = true;
  };

  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 25565 ];
  };

  # https://discourse.nixos.org/t/nixos-rebuild-switch-is-failing-when-systemd-linger-is-enabled/31937/5
  systemd.user.services.nixos-activation.unitConfig.ConditionUser = lib.mkForce [
    "!minecraft"
  ];

  nginx.subdomain.minecraft."/" = {
    extraConfig = # nginx
      ''
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
