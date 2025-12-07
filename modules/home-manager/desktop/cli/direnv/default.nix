{ config, ... }:
{
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    # https://github.com/nix-community/nix-direnv
    nix-direnv.enable = true;
  };

  xdg.configFile."direnv/lib/_layout.sh".source = config.lib.file.mkFlakeSymlink ./_layout.sh;
}
