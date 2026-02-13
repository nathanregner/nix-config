{ config, pkgs, ... }:
{
  services.grafana = {
    enable = true;
    settings = {
      "auth.proxy" = {
        enabled = true;
        header_name = "X-WEBAUTH-EMAIL";
        header_property = "email";
        auto_sign_up = true;
        whitelist = "127.0.0.0/8";
        sync_ttl = 15;
      };
      server = {
        domain = "grafana.nregner.net";
        http_addr = "127.0.0.1";
        http_port = 3004;
      };
      # https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/auth-proxy/
      users = {
        allow_sign_up = false;
        auto_assign_org = true;
        auto_assign_org_role = "Editor";
      };
    };

    provision = {
      enable = true;

      dashboards.settings.providers = [
        {
          name = "Host Monitoring";
          options.path = "/etc/grafana.d/dashboards";
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
    source = pkgs.local.node-exporter-full;
    group = "grafana";
    user = "grafana";
  };

  nginx.subdomain.grafana = {
    "/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
      extraConfig = # nginx
        ''
          proxy_set_header X-WEBAUTH-EMAIL $email;
        '';
    };
  };

  services.oauth2-proxy = {
    nginx.virtualHosts."grafana.nregner.net" = { };
  };

  local.services.backup.jobs.grafana = {
    dynamicFilesFrom = "realpath ${config.services.grafana.dataDir}";
  };
}
