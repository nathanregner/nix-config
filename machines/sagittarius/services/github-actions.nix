{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  disabledModules = [
    "services/continuous-integration/github-runner.nix"
    "services/continuous-integration/github-runners.nix"
  ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/continuous-integration/github-runners.nix"
  ];

  nix.buildMachines = [
    {
      hostName = "iapetus";
      protocol = "ssh-ng";
      sshUser = "nregner";
      system = "x86_64-linux";
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      maxJobs = 12;
    }
    {

      hostName = "enceladus";
      protocol = "ssh-ng";
      sshUser = "nregner";
      systems = [ "aarch64-darwin" ];
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
      ];
      maxJobs = 12;
    }
    {
      hostName = "enceladus-linux-vm";
      protocol = "ssh-ng";
      sshUser = "nregner";
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

  # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
  sops.secrets.nix-config-github-runner-pat = {
    key = "nix-config-github-runner/pat";
    owner = "github";
  };

  services.github-runners = lib.genAttrs [ "nix-config-1" "nix-config-2" ] (attr: {
    enable = true;
    name = "${config.networking.hostName}-${attr}";
    replace = true;
    url = "https://github.com/nathanregner/nix-config";
    tokenFile = config.sops.secrets.nix-config-github-runner-pat.path;
    user = "github";
    group = "github";
    extraPackages = with pkgs.unstable; [
      nix-fast-build
      node2nix
      nushell
      nvfetcher
      wol
    ];
    extraEnvironment = {
      NVFETCHER_KEYFILE = config.sops.templates.nvfetcher-github-pat.path;
    };
  });

  users = {
    users.github = {
      group = "github";
      isSystemUser = true;
    };
    groups.github = { };
  };

  nix.settings.trusted-users = [ "github" ];

  # https://discourse.nixos.org/t/flakes-provide-github-api-token-for-rate-limiting/18609/3
  sops.templates.nix-config-github-pat = {
    content = ''
      access-tokens = github.com = ${config.sops.placeholder.nix-config-github-runner-pat}
    '';
    owner = "github";
  };
  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config-github-pat.path}
  '';

  # https://github.com/berberman/nvfetcher/issues/86
  sops.templates.nvfetcher-github-pat = {
    content = ''
      [keys]
      github = "${config.sops.placeholder.nix-config-github-runner-pat}"
    '';
    owner = "github";
  };
}
