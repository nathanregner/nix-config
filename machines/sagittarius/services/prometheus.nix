{ self, config, ... }:
{
  # https://wiki.nixos.org/wiki/Prometheus
  # https://nixos.org/manual/nixos/stable/#module-services-prometheus-exporters-configuration
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/default.nix
  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "host_metrics";
        static_configs =
          builtins.map
            (node: {
              targets = [
                "${node}:${toString self.globals.services.prometheus.node.port}"
              ];
            })
            [
              "iapetus"
              "sagittarius"
              "sunlu-s8-0"
              "voron"
            ];
      }
      {
        job_name = "nginx";
        static_configs = [
          { targets = [ "localhost:${toString config.services.prometheus.exporters.nginx.port}" ]; }
        ];
      }
      {
        job_name = "nginxlog";
        static_configs = [
          { targets = [ "localhost:${toString config.services.prometheus.exporters.nginxlog.port}" ]; }
        ];
      }
    ];
  };
}
