# sudo su hydra
# hydra-create-user nregner --full-name "Nathan Regner" --email-address nathanregner@gmail.com --password-prompt --role admin

# sudo su hydra-queue-runner
# ssh builder@enceladus-linux-vm

{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.hydra-sentinel.nixosModules.server ];

  services.hydra = {
    enable = true;
    package = pkgs.unstable.hydra_unstable.overrideAttrs { doCheck = false; };
    hydraURL = "https://hydra.nregner.net";
    notificationSender = "hydra@nregner.net";
    useSubstitutes = true;
    port = 3001;
    buildMachinesFiles = [
      "/var/lib/hydra/machines"
      (pkgs.writeTextFile {
        name = "local-machine";
        text = "localhost ${pkgs.system} - 10 1 nixos-test,benchmark,big-parallel,kvm - -";
      })
    ];
    extraConfig = ''
      evaluator_workers = 10
      max_output_size = ${toString (4 * 1024 * 1024 * 1024)}
      always_supported_system_types = ${
        lib.concatStringsSep "," [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ]
      }
    '';
  };

  nix.settings.trusted-users = [ "hydra" ];

  services.postgresql.identMap = ''
    hydra-users nregner hydra
  '';

  sops.secrets.hydra-github-webhook-secret = {
    key = "hydra/github_webhook_secret";
    owner = "hydra-sentinel-server";
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
          systems = [ "x86_64-linux" ];
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
    "/".proxyPass = "http://127.0.0.1:${toString config.services.hydra.port}/";
    "/github/webhook".proxyPass =
      "http://127.0.0.1:${toString config.services.hydra-sentinel-server.listenPort}/webhook";
  };
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
