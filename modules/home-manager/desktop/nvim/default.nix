{ config, pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = ''
      vim.g.copilot_node_command = '${pkgs.unstable.nodejs_20}/bin/node'
      require('user')
    '';

    plugins = with pkgs.unstable.vimPlugins; [ lazy-nvim ];

    extraPackages = with pkgs.unstable; [

      # language servers
      clojure-lsp
      gopls
      lua-language-server
      nil
      nodePackages_latest.graphql-language-service-cli
      nodePackages_latest.typescript-language-server
      nodePackages_latest.volar
      rust-analyzer-unwrapped
      terraform-ls
      vscode-langservers-extracted

      # formatters/linters
      codespell
      pkgs.joker
      prettierd
      shfmt
      stylua

      # test runners
      cargo-nextest # for rouge8/neotest-rust

      # misc
      gnumake
      clang # for compiling tree-sitter parsers
    ];
  };

  xdg.configFile = {
    "nvim/lua".source = config.lib.file.mkFlakeSymlink ./lua;
    "nvim/after".source = config.lib.file.mkFlakeSymlink ./after;
    "nvim/lazy-lock.json".source =
      config.lib.file.mkFlakeSymlink ./lazy-lock.json;
  };

  programs.zsh.shellAliases.vimdiff = "nvim -d";

  # https://github.com/jesseduffield/lazygit/wiki/Custom-Commands-Compendium
  programs.lazygit.settings.customCommands = [{
    key = "M";
    command = "nvim -c DiffviewOpen";
    description = "Open diffview.nvim";
    context = "files";
    loadingText = "opening diffview.nvim";
    subprocess = true;
  }];
}
