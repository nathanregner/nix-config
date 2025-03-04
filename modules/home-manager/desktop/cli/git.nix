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
        ddiff = "-c diff.external=difft diff";
        diff-refactor = ''
          -c color.diff.oldMoved='white dim'
          -c color.diff.oldMovedAlternative='white dim'
          -c color.diff.newMoved='white dim'
          -c color.diff.newMovedAlternative='white dim'
          -c color.diff.newMovedDimmed='white dim'
          -c color.diff.newMovedAlternativeDimmed='white dim'
          diff --ignore-blank-lines --color-moved=dimmed-zebra --color-moved-ws=ignore-all-space --minimal'';
        dlog = "-c diff.external=difft log --ext-diff";
        dshow = "-c diff.external=difft show --ext-diff";
      };
      branch = {
        sort = "-committerdate";
      };
      commit = {
        verbose = true;
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
        tool = lib.mkDefault "difftastic"; # https://difftastic.wilfred.me.uk/git.html
      };
      difftool = {
        difftastic.cmd = ''difft "$MERGED" "$LOCAL" "abcdef1" "100644" "$REMOTE" "abcdef2" "100644"'';
        prompt = false;
      };
      fetch = {
        all = true;
        prune = true;
        pruneTags = true;
      };
      include = {
        path = "${config.xdg.configHome}/git/local";
      };
      merge = {
        conflictStyle = "zdiff3";
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
        autoupdate = true;
        enabled = true;
      };
      tag = {
        sort = "version:refname";
      };
    };
    ignores = [
      "Session.vim"
      ".direnv"
    ];
  };

  home.packages = with pkgs.unstable; [ difftastic ];
}
