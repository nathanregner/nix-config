{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.local.claude-code;

    settings = {
      model = "claude-opus-4-5";
      permissions = {
        defaultMode = "acceptEdits";
        allow = [
          "Bash(cargo clean:*)"
          "Bash(cargo doc:*)"
          "Bash(cargo info:*)"
          "Bash(cargo tree:*)"
          "Bash(cat:*)"
          "Bash(echo:*)"
          "Bash(git cp:*)"
          "Bash(git diff:*)"
          "Bash(git mv:*)"
          "Bash(grep:*)"
          "Bash(ls:*)"
          "Bash(tree:*)"
          "Read(/nix/store/**)"
          "Read(~/.cargo/registry/**)"
          "WebFetch"
          "WebSearch"
        ];
        ask = [
        ];
        deny = [
          "Read(**/*.key)"
          "Read(**/*.pem)"
          "Read(**/.aws/**)"
          "Read(**/.env*)"
          "Read(**/.ssh/**)"
          "Read(**/secrets/**)"
        ];
      };

      hooks = {
        Notification = [
          {
            hooks = [
              {
                command = "tmux-claude-status-hook Notification";
                type = "command";
              }
            ];
          }
        ];
        PreToolUse = [
          {
            hooks = [
              {
                command = "tmux-claude-status-hook PreToolUse";
                type = "command";
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                command = "tmux-claude-status-hook Stop";
                type = "command";
              }
            ];
          }
        ];
        UserPromptSubmit = [
          {
            hooks = [
              {
                command = "tmux-claude-status-hook UserPromptSubmit";
                type = "command";
              }
            ];
          }
        ];
      };
    };
  };

  programs.git.ignores = [
    ".claude"
  ];

  programs.zsh = {
    enable = true;
    initContent = lib.optionalString config.programs.direnv.enable /* zsh */ ''
      if [[ ! -z "$CLAUDECODE" ]]; then
        eval "$(direnv hook zsh)"
        eval "$(DIRENV_LOG_FORMAT= direnv export zsh)"  # Need to trigger "hook" manually
      fi
    '';
  };

  programs.tmux = {
    extraConfig = /* tmux */ ''
      set -g @claude-status-key "a"
      set -g @claude-next-done-key "c-n"
      set -g @claude-wait-key "w"
    '';

    plugins = [
      pkgs.local.tmux-claude-status
    ];
  };

  home.packages = [
    pkgs.local.tmux-claude-status
  ];
}
