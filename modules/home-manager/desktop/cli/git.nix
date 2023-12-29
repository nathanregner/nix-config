{ inputs, config, pkgs, ... }: {
  programs.git = {
    enable = true;
    userName = "Nathan Regner";
    userEmail = "nathanregner@gmail.com";
    lfs.enable = true;
    extraConfig = {
      push = { autoSetupRemote = true; };
      # use difftastic as difftool: https://difftastic.wilfred.me.uk/git.html
      diff.tool = "difftastic";
      difftool = {
        prompt = false;
        difftastic.cmd = ''difft "$LOCAL" "$REMOTE"'';
      };
      pager.difftool = true;
      alias = {
        difft = "difftool";
        dlog = "!f() { GIT_EXTERNAL_DIFF=difft git log -p --ext-diff; }; f";
      };
    };
  };

  home.packages = with pkgs.unstable; [ commitizen difftastic ];

  programs.lazygit = {
    enable = true;
    # pull in https://github.com/jesseduffield/lazygit/pull/2738
    package = let
      version = "1d1b8cc01f87bb3495426ac8d81d97573f6840d4";
      src = pkgs.fetchFromGitHub {
        owner = "jesseduffield";
        repo = "lazygit";
        rev = version;
        hash = "sha256-Qt50tBA7zAHoHv/GzpTcwpkJvq3TO96D8ClAw2TaABI=";
      };
    in pkgs.unstable.lazygit.override {
      buildGoModule = args:
        pkgs.unstable.buildGoModule (args // { inherit src version; });
    };
    # https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
    settings = {
      gui = (config.lib.formats.fromYAML
        "${inputs.catppuccin-lazygit}/themes/mocha/blue.yml") // {
          nerdFontsVersion = "3";
        };

      keybinding = {
        universal = {
          quit = "<c-c>";
          return = "q";
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

      # https://github.com/jesseduffield/lazygit/wiki/Custom-Commands-Compendium
      customCommands = [{
        key = "C";
        command = "git cz c";
        description = "commit with commitizen";
        context = "files";
        loadingText = "opening commitizen commit tool";
        subprocess = true;
      }];
    };
  };
}
