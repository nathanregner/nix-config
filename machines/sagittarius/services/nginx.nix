{
  options,
  config,
  lib,
  ...
}:
let
  oauth2-proxy-user = config.systemd.services.oauth2-proxy.serviceConfig.User;
  inherit (lib) types mkOption;
in
{
  options.nginx.subdomain = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          oauth2-proxy = mkOption (
            let
              base = options.services.oauth2-proxy.nginx.virtualHosts;
            in
            {
              type = types.nullOr base.type;
              inherit (base) example;
              default = null;
            }
          );
          locations = mkOption {
            inherit ((options.services.nginx.virtualHosts.type.getSubOptions [ ]).locations)
              type
              default
              example
              ;
          };
        };
      }
    );
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
        environmentFile = config.sops.secrets.acme.path;
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
      experimentalZstdSettings = true;

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
        // lib.mapAttrs' (subdomain: cfg: {
          name = "${subdomain}.nregner.net";
          value = virtualHost (
            cfg.locations
            // lib.optionalAttrs (cfg.oauth2-proxy != null) {
              # "@redirectToAuth2ProxyLogin" = {
              #   # retain subdomain
              #   # return = "307 https://${cfg.domain}/oauth2/start?rd=$scheme://$host$request_uri";
              #   return = lib.mkForce "307 https://$host/oauth2/start?rd=$scheme://$host$request_uri";
              # };
            }
          );
        }) config.nginx.subdomain;
    };

    services.prometheus.exporters = {
      nginx.enable = true;
      nginxlog.enable = true;
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
    sops.secrets.oauth2-proxy-emails = {
      key = "oauth2-proxy/emails";
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
        virtualHosts = lib.pipe config.nginx.subdomain [
          (lib.filterAttrs (_: cfg: cfg.oauth2-proxy != null))
          (lib.mapAttrs' (
            subdomain: cfg: {
              name = "${subdomain}.nregner.net";
              value = cfg.oauth2-proxy;
            }
          ))
        ];
      };
      clientID = "397693947419-n7dljfbjdrs7da82o1mpa9fhoafo7467.apps.googleusercontent.com";
      google = {
        serviceAccountJSON = config.sops.secrets.oauth2-proxy-google-service-account.path;
      };
      cookie = {
        domain = "nregner.net";
      };
      approvalPrompt = "auto";
      extraConfig = {
        authenticated-emails-file = config.sops.secrets.oauth2-proxy-emails.path;
        client-secret-file = config.sops.secrets.oauth2-proxy-client-secret.path;
        whitelist-domain = ".nregner.net";
      };
      keyFile = config.sops.templates.oauth2-proxy-env.path;
      setXauthrequest = true;
    };
  };
}
