{ config, pkgs, lib, ... }: {
  services.k3s = {
    enable = true;
    package = pkgs.unstable.k3s;
    role = "server";
    extraFlags = "--disable=traefik";
  };

  # fixes hang on shutdown but breaks nondistruptive upgrades
  # https://github.com/k3s-io/k3s/issues/2400#issuecomment-711065914
  systemd.services.k3s.serviceConfig.KillMode = lib.mkForce "Mixed";

  environment.systemPackages = [ config.services.k3s.package ];
}
