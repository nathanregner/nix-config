{
  sources,
  config,
  pkgs,
  ...
}:
{
  programs.lazygit = {
    enable = true;
    # https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#overriding-default-config-file-location
    package = pkgs.unstable.callPackage (
      {
        runCommand,
        makeWrapper,
        lazygit,
        formats,
        remarshal,
        jq,
        ...
      }:
      let
        yamlFormat = formats.yaml { };
        settingsFile = yamlFormat.generate "lazygit.yaml" config.programs.lazygit.settings;
        catppuccin = config.programs.lazygit.catppuccin;
        theme = "${sources.catppuccin.lazygit}/themes-mergable/${catppuccin.flavor}/${catppuccin.accent}.yml";
      in
      runCommand "lazygit-wrapper" { nativeBuildInputs = [ makeWrapper ]; } ''
        makeWrapper ${lazygit}/bin/lazygit $out/bin/lazygit \
          --add-flags '--use-config-file="${theme},${settingsFile}"'
      ''
    ) { };
    # https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
    settings = {
      gui = {
        nerdFontsVersion = "3";
      };

      keybinding = {
        universal = {
          quit = "<c-c>";
        };
        files = {
          # always commit with EDITOR (also prevents us from getting stuck thanks to "q" remap)
          commitChanges = "";
          commitChangesWithEditor = "c";
        };
        commits = {
          # fix conflicts with tmux
          moveDownCommit = "<c-N>";
          moveUpCommit = "<c-P>";
        };
      };

      promptToReturnFromSubprocess = false;
    };
  };
}
