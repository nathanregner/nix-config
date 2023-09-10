{ pkgs, lib, ... }: {
  services.k3s = {
    enable = true;
    role = "server";
  };

  # fixes hang on shutdown but breaks nondistruptive upgrades
  # https://github.com/k3s-io/k3s/issues/2400#issuecomment-711065914
  systemd.services.k3s.serviceConfig.KillMode = lib.mkForce "Mixed";

  networking.firewall.allowedTCPPorts = [ 6443 ];

  environment.systemPackages = with pkgs; [ k3s ];
}
