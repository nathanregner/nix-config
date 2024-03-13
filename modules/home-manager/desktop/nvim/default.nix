{ config, pkgs, ... }: {
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
      gopls
      lua-language-server
      nil
      nodePackages_latest.graphql-language-service-cli
      nodePackages_latest.typescript-language-server
      nodePackages_latest.volar
      rust-analyzer-unwrapped
      terraform-ls

      # formatters/linters
      codespell
      nodePackages_latest.prettier
      (prettierd.overrideAttrs {
        src = fetchFromGitHub {
          owner = "fsouza";
          repo = "prettierd";
          rev = "0d077fe55711bba2c6c6756a953cf04e5acce86c";
          hash = "sha256-EQHnQo8NQLP1+2QmtmeV4t/b1yFmrwC6Fdoe69/QEAE=";
        };
      })
      stylua
      pkgs.joker

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

  home.packages = [
    (pkgs.unstable.jdt-language-server.overrideAttrs rec {
      version = "1.30.0";
      src = let timestamp = "202311301503";
      in pkgs.unstable.fetchurl {
        url =
          "https://download.eclipse.org/jdtls/milestones/${version}/jdt-language-server-${version}-${timestamp}.tar.gz";
        hash = "sha256-V5gJ8n319OU1ZiF/cnP6Jc1Foi04cMCq/U+EzdTJes0=";
      };
    })
  ];

}
