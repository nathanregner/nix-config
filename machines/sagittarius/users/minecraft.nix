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
    # FIXME: bind address
    proxyPass = "https://192.168.0.8:8443/";
    extraConfig = ''
      client_max_body_size 0;
    '';
  };
}
