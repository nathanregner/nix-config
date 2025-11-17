{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
  };
  catppuccin.eza.enable = true;

  # lazy fix for mismatched config path on darwin
  home.file."Library/Application Support/eza".source = lib.mkIf pkgs.stdenv.isDarwin (
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/eza"
  );
}
