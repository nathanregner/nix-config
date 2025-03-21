{
  self,
  lib,
  ...
}:
{
  users.users.factorio = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
    linger = true;
  };

  networking.firewall = {
    allowedUDPPorts = [ 34197 ];
  };

  users.users.craigslist = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
    linger = true;
  };

  virtualisation.podman.enable = true;

  # https://discourse.nixos.org/t/nixos-rebuild-switch-is-failing-when-systemd-linger-is-enabled/31937/5
  systemd.user.services.nixos-activation.unitConfig.ConditionUser = lib.mkForce [
    "!craigslist"
    "!factorio"
  ];

  services.nregner.backup.paths.home = {
    paths = [ "/home" ];
    restic = {
      s3 = { };
    };
  };
}
