{
  pkgs,
  lib,
  ...
}:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = lib.mkDefault "client";
    package = pkgs.unstable.tailscale;
  };
}
