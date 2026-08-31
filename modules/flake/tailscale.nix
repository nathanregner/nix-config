{ lib, ... }:
let
  mkModule =
    cfg:
    (lib.mkMerge [
      ({ config, ... }: {
        services.tailscale.enable = true;
        environment.systemPackages = [ config.services.tailscale.package ];
      })
      cfg
    ]);
in
{
  flake.modules.nixos.tailscale = mkModule (
    { config, lib, ... }: {
      services.tailscale = {
        useRoutingFeatures = lib.mkDefault "client";
      };
      networking.firewall = {
        trustedInterfaces = [ "tailscale0" ];
        allowedUDPPorts = [ config.services.tailscale.port ];
      };
    }
  );

  flake.modules.darwin.tailscale = mkModule {
    services.tailscale = {
      overrideLocalDns = true;
    };
    # FIXME
    # https://github.com/tailscale/tailscale/issues/20890
    # https://github.com/tailscale/tailscale/issues/19139
    multiverse.pins.tailscale = "1.98.10";
  };
}
