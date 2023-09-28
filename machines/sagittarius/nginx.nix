{ config, lib, ... }: {
  options.nginx.subdomain = lib.mkOption {
    type = lib.types.attrs;
    description = "subdomain -> virtualHosts.*.location";
  };

  config = {
    sops.secrets.acme.key = "route53/acme";

    security.acme = {
      acceptTerms = true;
      defaults.email = "nathanregner@gmail.com";
      certs."nregner.net" = {
        domain = "*.nregner.net";
        dnsProvider = "route53";
        credentialsFile = config.sops.secrets.acme.path;
      };
    };

    services.nginx = {
      enable = true;

      # Use recommended settings
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;

      virtualHosts = let
        virtualHost = locations: {
          inherit locations;
          forceSSL = true;
          useACMEHost = "nregner.net";
        };
      in {
        "craigslist.nregner.net" =
          virtualHost { "/".proxyPass = "http://127.0.0.1:8888/"; };
        "craigslist-api.nregner.net" = virtualHost {
          "/" = {
            proxyPass = "http://127.0.0.1:6000/";
            extraConfig = ''
              proxy_hide_header Access-Control-Allow-Origin;
              proxy_hide_header Access-Control-Allow-Credentials;
              proxy_hide_header Access-Control-Allow-Headers;
              proxy_hide_header Access-Control-Allow-Methods;

              add_header Access-Control-Allow-Origin https://craigslist.nregner.net always;
              add_header Access-Control-Allow-Credentials true always;
              add_header Access-Control-Allow-Headers * always;
              add_header Access-Control-Allow-Methods * always;
            '';
          };
        };

        "nregner.net" = {
          extraConfig = ''
            rewrite ^/craigslist(.*)$ https://craigslist.nregner.net$1 redirect;
          '';
        };
      } // lib.mapAttrs' (subdomain: location: {
        name = "${subdomain}.nregner.net";
        value = virtualHost location;
      }) config.nginx.subdomain;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    users.users.nginx.extraGroups = [ "acme" ];
  };
}
