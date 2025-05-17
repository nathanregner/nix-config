{ config, lib, ... }:
let
  oauth2-proxy-user = config.systemd.services.oauth2-proxy.serviceConfig.User;
in
{
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
        extraDomainNames = [ "*.nregner.net" ];
        dnsProvider = "route53";
        # propagation check always times out... issue with IPv6 configuration?
        # https://github.com/go-acme/lego/issues/355
        dnsPropagationCheck = false;
        credentialsFile = config.sops.secrets.acme.path;
      };
    };

    services.nginx = {
      enable = true;
      enableReload = true;

      # Use recommended settings
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;

      virtualHosts =
        let
          virtualHost = locations: {
            inherit locations;
            forceSSL = true;
            useACMEHost = "nregner.net";
          };
        in
        {
          "nregner.net" = virtualHost {
            "/" = {
              extraConfig = ''
                rewrite ^/craigslist(.*)$ https://craigslist.nregner.net$1 redirect;
              '';
            };
          };
        }
        // lib.mapAttrs' (subdomain: location: {
          name = "${subdomain}.nregner.net";
          value = virtualHost location;
        }) config.nginx.subdomain;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    users.users.nginx.extraGroups = [ "acme" ];

    sops.secrets.oauth2-proxy-client-secret = {
      key = "oauth2-proxy/client-secret";
      owner = oauth2-proxy-user;
    };
    sops.secrets.oauth2-proxy-cookie-secret = {
      key = "oauth2-proxy/cookie-secret";
      owner = oauth2-proxy-user;
    };
    sops.secrets.oauth2-proxy-google-service-account = {
      key = "oauth2-proxy/google-service-account";
      owner = oauth2-proxy-user;
    };
    sops.templates.oauth2-proxy-env = {
      content = ''
        OAUTH2_PROXY_COOKIE_SECRET=${config.sops.placeholder.oauth2-proxy-cookie-secret}
      '';
      owner = oauth2-proxy-user;
    };

    services.oauth2-proxy = {
      enable = true;
      nginx = {
        domain = "nregner.net";
      };
      email.addresses = ''
        nathanregner@gmail.com
      '';
      clientID = "397693947419-n7dljfbjdrs7da82o1mpa9fhoafo7467.apps.googleusercontent.com";
      clientSecret = null;
      google = {
        serviceAccountJSON = config.sops.secrets.oauth2-proxy-google-service-account.path;
      };
      cookie = {
        domain = "nregner.net";
        secret = null;
      };
      approvalPrompt = "auto";
      extraConfig = {
        client-secret-file = config.sops.secrets.oauth2-proxy-client-secret.path;
      };
      keyFile = config.sops.templates.oauth2-proxy-env.path;
    };
  };
}
