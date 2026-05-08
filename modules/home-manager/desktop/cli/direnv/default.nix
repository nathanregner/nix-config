{ config, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # https://github.com/nix-community/nix-direnv
    nix-direnv.enable = true;
  };

  programs.claude-code.merged-hooks.PreToolUse = [
    { command = toString ./direnv-hook.nu; }
  ];

  programs.claude-code.sandbox.roStateDirs = [
    "${config.xdg.dataHome}/direnv"
    "${config.xdg.configHome}/direnv"
  ];

  xdg.configFile."direnv/lib/_layout.sh".source = config.lib.file.mkFlakeSymlink ./_layout.sh;
}
