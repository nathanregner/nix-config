{ config, pkgs, ... }:
{
  catppuccin.k9s.enable = true;
  programs.k9s = {
    enable = true;
    package = pkgs.unstable.k9s;
    plugin.plugins = {
      stern = {
        args = [
          "--tail"
          50
          "$FILTER"
          "-n"
          "$NAMESPACE"
          "--context"
          "$CONTEXT"
        ];
        background = false;
        command = "stern";
        confirm = false;
        description = "Logs <Stern>";
        scopes = [
          "pods"
          "deployments"
        ];
        shortCut = "Ctrl-Y";
      };
    };
  };

  xdg.enable = true;

  # lazy fix for mismatched config path on darwin
  imports = [
    (
      { pkgs, lib, ... }:
      {
        config = lib.mkIf pkgs.stdenv.isDarwin {
          home.file."Library/Application Support/k9s".source =
            config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/k9s";
        };
      }
    )
  ];
}
