# sudo su hydra
# hydra-create-user nregner --full-name "Nathan Regner" --email-address nathanregner@gmail.com --password-prompt --role admin

# sudo su hydra-queue-runner
# ssh builder@enceladus-linux-vm

{
  self,
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  prometheusAddress = "127.0.0.1:9198";
in
{
  imports = [ inputs.hydra-sentinel.nixosModules.server ];

  services.hydra = {
    enable = true;
    package = pkgs.unstable.hydra;
    hydraURL = "https://hydra.nregner.net";
    notificationSender = "hydra@nregner.net";
    useSubstitutes = true;
    inherit (self.globals.services.hydra) port;
    buildMachinesFiles = [
      "/var/lib/hydra/machines"
      (pkgs.writeTextFile {
        name = "local-machine";
        text = "localhost ${pkgs.stdenv.hostPlatform.system} - 10 1 nixos-test,benchmark,big-parallel,kvm - -";
      })
    ];
    extraConfig = ''
      evaluator_workers = 10
      max_output_size = ${toString (4 * 1024 * 1024 * 1024)}
      max_unsupported_time_in_s = ${toString (1 * 60 * 60)}
      always_supported_system_types = ${
        lib.concatStringsSep "," [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "i686-linux"
        ]
      }

      queue_runner_metrics_address = ${prometheusAddress}

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
      buildMachines = [
        {
          hostName = "enceladus";
          sshUser = "nregner";
          systems = [ "aarch64-darwin" ];
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
          ];
          maxJobs = 12;
          macAddress = "60:3e:5f:4e:4e:bc";
          vms = [
            {
              hostName = "enceladus-linux-vm";
              sshUser = "builder";
              systems = [ "aarch64-linux" ];
              supportedFeatures = [
                "nixos-test"
                "benchmark"
                "big-parallel"
                "kvm"
                "gccarch-armv8-a"
              ];
              maxJobs = 8;
            }
          ];
        }
        {
          hostName = "iapetus";
          sshUser = "nregner";
          systems = [ "x86_64-linux" "i686-linux" ];
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          maxJobs = 12;
          speedFactor = 2;
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
        proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}";
        extraConfig = /* nginx */ ''
          proxy_set_header X-Remote-User $user;
          proxy_set_header X-Remote-Roles $hydra_roles;
        '';
      };
      "/github/webhook" = {
        proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}/api/push-github";
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
