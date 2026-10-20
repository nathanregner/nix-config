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
        # lazygit tries to migrate gui.authorColors -> gui.theme.authorColors in place, which fails on the read-only store
        themePkg = pkgs.runCommand "catppuccin-lazygit-migrated" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
          cp -r ${inputs.catppuccin-nix.packages.${pkgs.stdenv.hostPlatform.system}.lazygit} $out
          chmod -R u+w $out
          for f in $(find $out -name '*.yml'); do
            yq -e '.gui.authorColors' "$f" > /dev/null
            yq -i '.gui.theme.authorColors = .gui.authorColors | del(.gui.authorColors)' "$f"
          done
        '';
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
        branches = {
          forceCheckoutBranch = "<c+s+f>";
        };
        commits = {
          # fix conflicts with tmux
          moveDownCommit = "<c+n>";
          moveUpCommit = "<c+p>";
          openLogMenu = "<c+g>";
        };
        files = {
          # always commit with EDITOR (also prevents us from getting stuck thanks to "q" remap)
          commitChanges = "";
          commitChangesWithEditor = "c";
        };
        universal = {
          quit = "<c+c>";
        };
      };

      promptToReturnFromSubprocess = false;
    };
  };

  home.packages = [
    (pkgs.writeShellApplication {
      name = "lazygit-large-repo";
      runtimeInputs = [ config.programs.git.package ];
      text = ''
        git_dir="$(git rev-parse --git-common-dir)"
        cp --no-preserve=all ${./large-repo.yml} "$git_dir/lazygit.yml"
      '';
    })
  ];
}
