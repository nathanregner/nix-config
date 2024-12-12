{ pkgs, ... }:
{
  catppuccin.lazygit.enable = true;
  programs.lazygit = {
    enable = true;
    package = pkgs.unstable.lazygit;
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
