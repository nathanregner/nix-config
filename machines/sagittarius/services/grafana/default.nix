{ config, pkgs, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3004;
      };
    };

    provision = {
      enable = true;

      dashboards.settings.providers = [
        {
          name = "Host Monitoring";
          options.path = "/etc/grafana/dashboards";
        }
      ];

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
        }
      ];
    };
  };

  environment.etc."grafana.d/dashboards/node-exporter-full.json" = {
    source = pkgs.node-exporter-full;
    group = "grafana";
    user = "grafana";
  };

  nginx.subdomain.grafana."/".extraConfig = # nginx
    "return 302 http://sagittarius:${toString config.services.grafana.settings.server.http_port}$request_uri;";
}
