{ pkgs, ... }: {

  programs.zsh = {
    enable = true;
    initExtra = ''
      bindkey -M viins 'jk' vi-cmd-mode

      # https://github.com/nix-community/nix-direnv/wiki/Shell-integration
      flakify() {
        if [ ! -e flake.nix ]; then
          nix flake new -t github:nix-community/nix-direnv .
        elif [ ! -e .envrc ]; then
          echo "use flake" > .envrc
          direnv allow
        fi
        ${"EDITOR"} flake.nix
      }
    '';
    # defaultKeymap = "viins";
    oh-my-zsh = {
      enable = true;
      plugins = [ "aws" "git" "vi-mode" ];
      # theme = "robbyrussell";
    };
    shellAliases = let
      nixRebuild =
        if pkgs.stdenv.isDarwin then "darwin-rebuild" else "nixos-rebuild";
      flakeRef = ''"git+file://$(pwd)?submodules=1"'';
    in rec {
      jqless = "jq -C | less -r";

      nr = "${nixRebuild} --flake ${flakeRef}";
      nrs = "${nr} switch";
      snr = "sudo ${nr}";
      snrs = "sudo ${nrs}";

      hm = "home-manager --flake ${flakeRef}";
      hms = "${hm} switch";

      npd = "nix profile diff-closures --profile /nix/var/nix/profiles/system";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Move directory to the second line
      format = "$all$directory$character";
      package.disabled = true;
      aws.disabled = true;
      nix_shell.disabled = true;
      docker_context = { only_with_files = false; };
      custom.direnv = {
        detect_files = [ ".envrc" ];
        when = ''[[ $(direnv status) =~ " Found RC allowed true " ]]'';
        format = "[ direnv](bold blue)";
      };
    };
  };
}
