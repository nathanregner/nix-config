{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.overlays = [ inputs.llm-agents.overlays.default ];

  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;

    settings = {
      model = "sonnet";
      permissions = {
        defaultMode = "acceptEdits";

        allow = [
          "Bash(cargo b:*)"
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

      fileSuggestion = {
        type = "command";
        command = pkgs.writeShellScript "claude-fzf" ''
          QUERY=$(jq -r '.query // ""')
          ${config.programs.fzf.defaultCommand} "''${CLAUDE_PROJECT_DIR:-.}" | fzf --filter "$QUERY"
        '';
      };
    };
  };

  programs.git.ignores = [
    "settings.local.json"
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

  home.packages = [ pkgs.llm-agents.claudebox ];
}
