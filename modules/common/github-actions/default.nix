{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.nregner.gha;
  owner = if pkgs.stdenv.isLinux then "github-runner" else "_github-runner";
  group = "github";
in
{
  imports = [ inputs.github-nix-ci.nixosModules.default ];

  options.services.nregner.gha = {
    enable = lib.mkEnableOption "Register this machine as a GHA builder";
  };

  config = lib.mkIf cfg.enable {
    services.github-nix-ci = {
      personalRunners =
        let
          tokenFile = config.sops.secrets.github-pat.path;
        in
        {
          "nathanregner/nix-config" = {
            num = 2;
            inherit tokenFile;
          };
          "nathanregner/print-farm" = {
            num = 2;
            inherit tokenFile;
          };
        };
      runnerSettings = {
        extraPackages = with pkgs.unstable; [
          nvfetcher
          nix-fast-build
          pkgs.gc-root
        ];
        extraEnvironment = {
          NVFETCHER_KEYFILE = config.sops.templates.nvfetcher-github-pat.path;
        };
      };
    };

    sops.secrets.github-pat = {
      sopsFile = ./secrets.yaml;
      key = "pat";
      inherit owner group;
    };

    # https://discourse.nixos.org/t/flakes-provide-github-api-token-for-rate-limiting/18609/3
    sops.templates.github-pat = {
      content = ''
        access-tokens = github.com = ${config.sops.placeholder.github-pat}
      '';
      inherit owner group;
    };
    nix.extraOptions = ''
      !include ${config.sops.templates.github-pat.path}
    '';

    # https://github.com/berberman/nvfetcher/issues/86
    sops.templates.nvfetcher-github-pat = {
      content = ''
        [keys]
        github = "${config.sops.placeholder.github-pat}"
      '';
      inherit owner group;
    };
  };
}