{
  self,
  config,
  lib,
  ...
}:
let
  cfg = config.services.prometheus-host-metrics;
in
{
  options.services.prometheus-host-metrics = {
    enable = lib.mkEnableOption "Export prometheus metrics to server";
  };

  config = lib.mkIf cfg.enable {

    # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters
    services.prometheus.exporters.node = {
      enable = true;
      port = self.globals.services.prometheus.port;
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
      enabledCollectors = [ "systemd" ];
      # node_exporter --help
      extraFlags = [
      ];
    };
  };
}
