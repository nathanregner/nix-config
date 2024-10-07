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
      commit.verbose = true;
      push = {
        autoSetupRemote = true;
      };
      pull.rebase = true;
      rebase.autostash = true;
      diff = {
        # use difftastic as difftool: https://difftastic.wilfred.me.uk/git.html
        tool = lib.mkDefault "difftastic";
        algorithm = "histogram";
      };
      difftool = {
        prompt = false;
        difftastic.cmd = ''difft "$LOCAL" "$REMOTE"'';
      };
      pager.difftool = true;
      rerere.enabled = true;
      alias = {
        difft = "difftool";
        dlog = "!f() { GIT_EXTERNAL_DIFF=difft git log -p --ext-diff; }; f";
        # https://github.com/orgs/community/discussions/9632#discussioncomment-4702442
        diff-refactor = ''
          -c color.diff.oldMoved='white dim'
          -c color.diff.oldMovedAlternative='white dim'
          -c color.diff.newMoved='white dim'
          -c color.diff.newMovedAlternative='white dim'
          -c color.diff.newMovedDimmed='white dim'
          -c color.diff.newMovedAlternativeDimmed='white dim'
          diff --ignore-blank-lines --color-moved=dimmed-zebra --color-moved-ws=ignore-all-space --minimal'';
      };
      include = {
        path = "${config.xdg.configHome}/git/local";
      };
    };
    ignores = [
      "Session.vim"
      ".direnv"
    ];
  };

  home.packages = with pkgs.unstable; [ difftastic ];
}
