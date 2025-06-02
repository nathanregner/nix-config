{ config, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # https://github.com/nix-community/nix-direnv
    nix-direnv.enable = true;
  };

  xdg.configFile."direnv/direnvrc" = {
    source = config.lib.file.mkFlakeSymlink ./direnvrc;
    force = true;
  };
}
