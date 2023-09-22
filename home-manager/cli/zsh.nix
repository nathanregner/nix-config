{ config, lib, pkgs, targetPlatform, ... }: {
  programs.zsh = {
    enable = true;
    initExtra = let
      templateRepo = pkgs.fetchFromGitHub {
        owner = "chriskempson";
        repo = "base16-shell";
        rev = "588691ba71b47e75793ed9edfcfaa058326a6f41";
        sha256 = "sha256-X89FsG9QICDw3jZvOCB/KsPBVOLUeE7xN3VCtf0DD3E=";
      };
      theme = config.lib.stylix.colors { inherit templateRepo; };
    in ''
      source ${theme}

      # Auto-start tmux
      if command -v tmux &> /dev/null \
          && [ -n "$PS1" ] \
          && [[ ! "$TERM" =~ screen ]] \
          && [[ ! "$TERM" =~ tmux ]] \
          && [ -z "$TMUX" ] \
          && [[ ! "$TERMINAL_EMULATOR" =~ "JetBrains" ]]; then
        tmux attach -t 0 || tmux new -s 0
      fi

      bindkey -M viins 'jk' vi-cmd-mode

      export EDITOR=nvim

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
    shellAliases = {
      jqless = "jq -C | less -r";

      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";

      npd = "nix profile diff-closures --profile /nix/var/nix/profiles/system";

      vim = "nvim";
      vi = "vim";
      v = "vim";
    } // lib.attrsets.optionalAttrs targetPlatform.isLinux {
      open = "xdg-open";
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
    };
  };

  home.packages = with pkgs;
    [ ] ++ lib.lists.optional targetPlatform.isLinux xclip;

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Move directory to the second line
      format = "$all$directory$character";
      package = { disabled = true; };
      aws = { disabled = true; };
      nix_shell = { disabled = true; };
      custom.direnv = {
        detect_files = [ ".envrc" ];
        when = ''[[ $(direnv status) =~ " Found RC allowed true " ]]'';
        format = "[ direnv](bold blue)";
      };
    };
  };
}
