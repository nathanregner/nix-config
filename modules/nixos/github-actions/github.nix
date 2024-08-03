{
  inputs,
  config,
  pkgs,
  ...
}:
let
  owner = if pkgs.stdenv.isLinux then "github-runner" else "_github-runner";
in
{
  imports = [ inputs.github-nix-ci.nixosModules.default ];

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
      extraPackages = with pkgs.unstable; [ nvfetcher ];
      extraEnvironment = {
        NVFETCHER_KEYFILE = config.sops.templates.nvfetcher-github-pat.path;
      };
    };
  };

  sops.secrets.github-pat = {
    sopsFile = ./secrets.yaml;
    key = "pat";
    inherit owner;
  };

  # https://discourse.nixos.org/t/flakes-provide-github-api-token-for-rate-limiting/18609/3
  sops.templates.github-pat = {
    content = ''
      access-tokens = github.com = ${config.sops.placeholder.github-pat}
    '';
    inherit owner;
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
    inherit owner;
  };
}
