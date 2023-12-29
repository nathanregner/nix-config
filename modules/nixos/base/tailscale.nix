{ config, lib, pkgs, ... }: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = lib.mkDefault "client";
    package = pkgs.unstable.tailscale;
  };
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  environment.systemPackages = [ config.services.tailscale.package ];
}
