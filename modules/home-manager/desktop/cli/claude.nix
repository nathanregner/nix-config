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
      availableModels = [
        "claude-sonnet-4-5"
        "claude-opus-4-5"
        "haiku"
      ];
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
          "mcp__ide__getDiagnostics"
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
}
