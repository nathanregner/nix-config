{ pkgs, ... }:
{
  catppuccin.lazygit.enable = true;
  programs.lazygit = {
    enable = true;
    # FIXME
    package = pkgs.unstable.lazygit.overrideAttrs {
      pname = "lazygit";
      version = "v0.44.1";
      src = pkgs.fetchFromGitHub {
        owner = "jesseduffield";
        repo = "lazygit";
        rev = "v0.44.1";
        fetchSubmodules = false;
        sha256 = "sha256-BP5PMgRq8LHLuUYDrWaX1PgfT9VEhj3xeLE2aDMAPF0=";
      };
    };
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
