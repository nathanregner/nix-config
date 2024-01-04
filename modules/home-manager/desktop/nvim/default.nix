{ config, pkgs, ... }: {
  xdg.configFile."nvim/lua".source = config.lib.file.mkFlakeSymlink ./lua;
  xdg.configFile."nvim/lazy-lock.json".source =
    config.lib.file.mkFlakeSymlink ./lazy-lock.json;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = ''
      vim.g.copilot_node_command = '${pkgs.unstable.nodejs_20}/bin/node'
      require('user')
    '';

    plugins = with pkgs.unstable.vimPlugins; [
      lazy-nvim

      # tmux <-> nvim navigation
      # Navigator-nvim

      # git
      # conflict-marker-vim
      # diffview-nvim

      # file type/syntax highlighting
      # (let plugin = nvim-treesitter;
      # in plugin.withAllGrammars.overrideAttrs (prev: {
      #   passthru.dependencies = prev.passthru.dependencies
      #     ++ [ (plugin.passthru.grammarToPlugin pkgs.tree-sitter-nu) ];
      # }))
      nvim-treesitter.withAllGrammars
      vim-nix

      # formatting
      # pkgs.conform-nvim
    ];
  };

  # https://github.com/sindrets/diffview.nvim/issues/324
  programs.git.extraConfig = {
    diff.tool = "nvim";
    difftool = {
      prompt = false;
      nvim.cmd = ''nvim -d \"$LOCAL\" \"$REMOTE\" -c \"DiffviewOpen\"'';
    };
    merge = { tool = "nvim"; };
    mergetool = {
      propmt = false;
      keepBackup = false;
      nvim.cmd = ''nvim -n -c "DiffviewOpen" "$MERGE"'';
    };
  };

  programs.zsh.shellAliases = { vimdiff = "nvim -d"; };

  home.packages = with pkgs.unstable; [
    clojure-lsp
    gopls
    lua-language-server
    nil
    nixd
    nodePackages_latest.graphql-language-service-cli
    nodePackages_latest.typescript-language-server
    nodePackages_latest.prettier
    prettierd
    stylua
    terraform-ls
  ];
}
