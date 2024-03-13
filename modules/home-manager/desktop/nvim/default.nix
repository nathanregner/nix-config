{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = ''
      vim.g.copilot_node_command = '${pkgs.unstable.nodejs_20}/bin/node'
      vim.g.java_home = '${pkgs.jdk21_headless}'
      vim.g.java_runtimes = {
        {
          name = "JavaSE-11",
          path = "${pkgs.jdk11_headless}",
        },
        {
          name = "JavaSE-17",
          path = "${pkgs.jdk17_headless}",
        },
      }
      require('user')
    '';

    plugins = with pkgs.unstable.vimPlugins; [ lazy-nvim ];

    extraPackages = with pkgs.unstable; [

      # language servers
      clojure-lsp
      emmet-language-server
      gopls
      lua-language-server
      nil
      nodePackages_latest.graphql-language-service-cli
      nodePackages_latest.typescript-language-server
      nodePackages_latest.volar
      rust-analyzer-unwrapped
      terraform-ls
      vscode-langservers-extracted
      yaml-language-server

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
    "nvim/lazy-lock.json".source = config.lib.file.mkFlakeSymlink ./lazy-lock.json;
  };

  programs.zsh.shellAliases.vimdiff = "nvim -d";

  # https://github.com/jesseduffield/lazygit/wiki/Custom-Commands-Compendium
  programs.lazygit.settings.customCommands = [
    {
      key = "M";
      command = "nvim -c DiffviewOpen";
      description = "Open diffview.nvim";
      context = "files";
      loadingText = "opening diffview.nvim";
      subprocess = true;
    }
  ];
}
