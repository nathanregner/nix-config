{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "Nathan Regner";
    userEmail = "nathanregner@gmail.com";
    lfs.enable = true;
    maintenance.enable = true;
    extraConfig = {
      alias = {
        # https://github.com/orgs/community/discussions/9632#discussioncomment-4702442
        diff-refactor = ''
          -c color.diff.oldMoved='white dim'
          -c color.diff.oldMovedAlternative='white dim'
          -c color.diff.newMoved='white dim'
          -c color.diff.newMovedAlternative='white dim'
          -c color.diff.newMovedDimmed='white dim'
          -c color.diff.newMovedAlternativeDimmed='white dim'
          diff --ignore-blank-lines --color-moved=dimmed-zebra --color-moved-ws=ignore-all-space --minimal'';
        difft = "difftool";
        dlog = "!f() { GIT_EXTERNAL_DIFF=difft git log -p --ext-diff; }; f";
      };
      commit = {
        verbose = true;
      };
      diff = {
        algorithm = "histogram";
        tool = lib.mkDefault "difftastic"; # https://difftastic.wilfred.me.uk/git.html
      };
      difftool = {
        difftastic.cmd = ''difft "$LOCAL" "$REMOTE"'';
        prompt = false;
      };
      include = {
        path = "${config.xdg.configHome}/git/local";
      };
      pager = {
        difftool = true;
      };
      pull = {
        rebase = true;
      };
      push = {
        autoSetupRemote = true;
      };
      rebase = {
        autostash = true;
      };
      rerere = {
        enabled = true;
      };
    };
    ignores = [
      "Session.vim"
      ".direnv"
    ];
  };

  home.packages = with pkgs.unstable; [ difftastic ];
}
