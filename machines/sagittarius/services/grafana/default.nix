{ config, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3004;
        domain = "grafana.nregner.net";
      };
      users = {
        allow_sign_up = false;
      };
      auth = {
        disable_login_form = true;
      };
      "auth.proxy" = {
        header_name = "X-Forwarded-Email";
        header_property = "email";
        auto_sign_up = true;
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

  environment.etc."grafana.d/dashboards" = {
    # https://grafana.com/grafana/dashboards/1860-node-exporter-full/
    source = ./dashboards;
    group = "grafana";
    user = "grafana";
  };

  nginx.subdomain.grafana = {
    "/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}/";
      proxyWebsockets = true;
    };
  };
}
