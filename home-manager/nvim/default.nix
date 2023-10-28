{ inputs, config, pkgs, ... }: {
  xdg.configFile."nvim/lua".source = config.lib.file.mkFlakeSymlink ./lua;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = ''
      vim.g.copilot_node_command = '${pkgs.unstable.nodejs_20}/bin/node'
      require('user')
    '';

    plugins = with pkgs.unstable.vimPlugins; [
      # theme
      catppuccin-nvim

      # tmux <-> nvim navigation
      Navigator-nvim

      # git
      conflict-marker-vim
      diffview-nvim

      # file type/syntax highlighting
      nvim-treesitter.withAllGrammars
      vim-nix

      # formatting
      pkgs.conform-nvim

      # misc
      lualine-nvim
      mini-nvim
      nvim-colorizer-lua
      nvim-tree-lua
      plenary-nvim
      telescope-fzy-native-nvim
      telescope-nvim
      vim-surround

      # lsp/completion
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp_luasnip
      copilot-lua
      friendly-snippets
      luasnip
    ];
  };

  programs.git.extraConfig = {
    merge = { tool = "vimdiff"; };
    mergetool.vimdiff = {
      cmd = "nvim -d $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
    };
  };

  home.packages = with pkgs.unstable; [
    # just get from rustup for now
    # rust-analyzer
    gopls
    lua-language-server
    nil
    nixd
    prettierd
    stylua
    terraform-ls
  ];
}
