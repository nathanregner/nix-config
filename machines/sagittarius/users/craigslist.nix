{ self, lib, ... }:
{
  users.users.craigslist = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
    openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
    linger = true;
  };

  virtualisation.podman.enable = true;

  nginx.subdomain = {
    craigslist."/".proxyPass = "http://127.0.0.1:8888/";
    craigslist-api."/".proxyPass = "http://127.0.0.1:6000/";
  };

  # https://discourse.nixos.org/t/nixos-rebuild-switch-is-failing-when-systemd-linger-is-enabled/31937/5
  systemd.user.services.nixos-activation.unitConfig.ConditionUser = lib.mkForce [
    "!craigslist"
  ];
}
