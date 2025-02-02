{
  inputs,
  config,
  pkgs,
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

  # https://docs.github.com/en/rest/actions/self-hosted-runners#create-a-registration-token-for-a-repository
  sops.secrets.nix-config-github-runner-pat = {
    key = "nix-config-github-runner/pat";
    owner = "github";
  };

  services.github-runners.nix-config = {
    enable = true;
    name = config.networking.hostName;
    replace = true;
    url = "https://github.com/nathanregner/nix-config";
    tokenFile = config.sops.secrets.nix-config-github-runner-pat.path;
    user = "github";
    group = "github";
  };

  services.github-runners.hydra-sentinel = {
    enable = true;
    name = config.networking.hostName;
    replace = true;
    url = "https://github.com/nathanregner/hydra-sentinel";
    tokenFile = config.sops.secrets.nix-config-github-runner-pat.path;
    user = "github";
    group = "github";
  };

  services.github-runners.platformio2nix = {
    enable = true;
    name = config.networking.hostName;
    replace = true;
    url = "https://github.com/nathanregner/platformio2nix";
    tokenFile = config.sops.secrets.nix-config-github-runner-pat.path;
    user = "github";
    group = "github";
  };

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
  services.github-runners.nix-config = {
    extraPackages = with pkgs.unstable; [
      node2nix
      nvfetcher
    ];
    extraEnvironment = {
      NVFETCHER_KEYFILE = config.sops.templates.nvfetcher-github-pat.path;
    };
  };
}
