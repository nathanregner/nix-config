# sudo su hydra
# hydra-create-user nregner --full-name "Nathan Regner" --email-address nathanregner@gmail.com --password-prompt --role admin

# sudo su hydra-queue-runner
# ssh builder@enceladus-linux-vm

# ssh -L 5432:/var/run/postgresql/.s.PGSQL.5432 -N 192.168.0.8

{
  self,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  prometheusAddress = "[::1]:${toString config.services.hydra-queue-runner-dev.rest.port}";
  grpcPort = config.services.hydra-queue-runner-dev.grpc.port;
in
{
  # upstream flake modules: the rust queue runner/evaluator and gRPC builders. not
  # nixosModules.hydra, which also includes the builder module that base already imports.
  imports = [
    inputs.hydra-sentinel.nixosModules.server
    inputs.hydra.nixosModules.web-app
    inputs.hydra.nixosModules.evaluator
    inputs.hydra.nixosModules.queue-runner
    inputs.hydra.nixosModules.ws-server
  ];

  services.hydra-dev = {
    enable = true;
    hydraURL = "https://hydra.nregner.net";
    notificationSender = "hydra@nregner.net";
    useSubstitutes = true;
    inherit (self.globals.services.hydra) port;
    extraConfig = ''
      evaluator_workers = 10
      ws_endpoint = wss://hydra.nregner.net/ws

      using_frontend_proxy = 1
      <proxy_auth>
        user_header = X-Remote-User
        roles_header = X-Remote-Roles
        disable_password_login = 1
      </proxy_auth>

      <webhooks>
        Include ${config.sops.templates.hydra-webhook-secrets.path}
      </webhooks>
    '';
  };

  services.hydra-queue-runner-dev = {
    enable = true;
    # builders connect over tailscale; see networking.firewall below
    grpc.address = "[::]";
    settings = {
      useSubstitutes = true;
      maxOutputSize = 4 * 1024 * 1024 * 1024;
      # builders sleep until hydra-sentinel wakes them, and iapetus can't be woken remotely.
      # there is no per-system exemption (always_supported_system_types was removed), so this
      # also delays failing builds for systems no builder supports.
      maxUnsupportedTimeInS = 7 * 24 * 60 * 60;
    };
  };

  services.hydra-ws-dev.enable = true;

  services.hydra-queue-builder-dev = {
    enable = true;
    queueRunnerAddr = "http://[::1]:${toString grpcPort}";
    settings.maxJobs = 10;
  };
  systemd.services.hydra-queue-builder-dev.after = [ "hydra-queue-runner-dev.service" ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ grpcPort ];

  services.prometheus.exporters.postgres.enable = true;

  services.postgresql.identMap = ''
    hydra-users nregner hydra
  '';

  local.services.backup.jobs.hydra = {
    dynamicFilesFrom = "${pkgs.writers.writeNu "pg_dump-hydra"
      {
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          "${lib.makeBinPath [ config.services.postgresql.finalPackage ]}"
        ];
      }
      # nu
      ''
        let tmp = mktemp -d
        pg_dump -d hydra -Z zstd -Fd -f $tmp
        $tmp
      ''
    }";
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "hydra";
      static_configs = [ { targets = [ prometheusAddress ]; } ];
    }
  ];

  sops.secrets.hydra-github-webhook-secret = {
    key = "hydra/github_webhook_secret";
    owner = "hydra-sentinel-server";
  };

  sops.templates.hydra-webhook-secrets = {
    content = ''
      <github>
        secret = ${config.sops.placeholder.hydra-github-webhook-secret}
      </github>
    '';
    owner = "hydra";
    group = "hydra";
    mode = "0660";
  };

  services.hydra-sentinel-server = {
    enable = true;
    listenHost = "0.0.0.0";
    listenPort = 3002;
    settings = {
      allowedIps = [
        "192.168.0.0/16"
        "100.0.0.0/8"
      ];
      githubWebhookSecretFile = config.sops.secrets.hydra-github-webhook-secret.path;
      # the default reads services.hydra.port, which is the unused nixpkgs module
      hydraBaseUrl = "http://127.0.0.1:${toString config.services.hydra-dev.port}";
      buildMachines = [
        {
          hostName = "enceladus";
          systems = [ "aarch64-darwin" ];
          macAddress = "60:3e:5f:4e:4e:bc";
          vms = [
            {
              hostName = "enceladus-linux-vm";
              systems = [ "aarch64-linux" ];
            }
          ];
        }
        {
          hostName = "iapetus";
          systems = [
            "x86_64-linux"
            "i686-linux"
          ];
          # macAddress = "00:d8:61:a3:ea:8c";
        }
      ];
    };
  };

  nix.extraOptions =
    let
      urls = [
        "https:"
        "github:"
      ];
    in
    ''
      extra-allowed-uris = ${lib.concatStringsSep " " urls}
    '';

  nginx.subdomain.hydra = {
    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.hydra-dev.port}";
        extraConfig = /* nginx */ ''
          proxy_set_header X-Remote-User $user;
          proxy_set_header X-Remote-Roles $hydra_roles;
        '';
      };
      "/ws" = {
        proxyPass = "http://${config.services.hydra-ws-dev.bind.address}:${toString config.services.hydra-ws-dev.bind.port}";
        proxyWebsockets = true;
      };
      "/github/webhook" = {
        proxyPass = "http://127.0.0.1:${toString config.services.hydra-dev.port}/api/push-github";
        extraConfig = "auth_request off;";
      };
    };
    oauth2-proxy = { };
  };

  services.nginx.appendHttpConfig = /* nginx */ ''
    map $email $hydra_roles {
      "nathanregner@gmail.com" "admin";
      default                  "";
    }
  '';

  # allow port forwarding to postgres socket
  services.openssh.settings.PermitListen = "any";
}

# programs.ssh.extraConfig = ''
#   Host enceladus-linux-vm
#     ProxyJump nregner@enceladus
#     HostKeyAlias enceladus-linux-vm
#     Hostname localhost
#     Port 31022
#     User nregner
# '';

# TODO: private repo access
# sudo su hydra
# cd /var/lib/hydra
# $ cat .ssh/config
# Host github.com
#         StrictHostKeyChecking No
#         UserKnownHostsFile /dev/null
#         IdentityFile /var/lib/hydra/.ssh/id_ed25519
