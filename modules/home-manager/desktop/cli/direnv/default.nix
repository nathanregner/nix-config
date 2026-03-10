{ config, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # https://github.com/nix-community/nix-direnv
    nix-direnv.enable = true;
  };

  xdg.configFile."direnv/lib/_layout.sh".source = config.lib.file.mkFlakeSymlink ./_layout.sh;

  programs.claude-code.merged-hooks.PreToolUse = [
    { command = ''DIRENV_LOG_FORMAT="-" direnv exec . $CMD''; }
  ];
}
