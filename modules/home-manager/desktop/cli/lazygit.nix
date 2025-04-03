{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  # https://github.com/catppuccin/nix/issues/455
  # catppuccin.lazygit.enable = true;
  programs.lazygit = {
    enable = true;
    package = pkgs.runCommand "lazygit-wrapped" { nativeBuildInputs = [ pkgs.makeWrapper ]; } (
      let
        cfg = config.catppuccin.lazygit;
        configDirectory =
          if !pkgs.stdenv.hostPlatform.isDarwin || config.xdg.enable then
            config.xdg.configHome
          else
            "${config.home.homeDirectory}/Library/Application Support";
        configFile = "${configDirectory}/lazygit/config.yml";
        themePkg = inputs.catppuccin-nix.packages.${pkgs.system}.lazygit;
      in
      ''
        makeWrapper ${lib.getExe pkgs.unstable.lazygit} $out/bin/lazygit \
          --prefix LG_CONFIG_FILE , "${themePkg}/${cfg.flavor}/${cfg.accent}.yml,${configFile}";
      ''
    );
    # https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
    settings = {
      gui = {
        nerdFontsVersion = "3";
      };

      keybinding = {
        commits = {
          # fix conflicts with tmux
          moveDownCommit = "<c-N>";
          moveUpCommit = "<c-P>";
          openLogMenu = "<c-g>";
        };
        files = {
          # always commit with EDITOR (also prevents us from getting stuck thanks to "q" remap)
          commitChanges = "";
          commitChangesWithEditor = "c";
        };
        universal = {
          quit = "<c-c>";
        };
      };

      promptToReturnFromSubprocess = false;
    };
  };
}
