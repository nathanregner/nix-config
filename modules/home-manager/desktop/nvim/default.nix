{ config, pkgs, ... }:
{
  imports = [ ./tools ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig =
      let
        globals = {
          jdtls = {
            lombok = pkgs.fetchurl {
              url = "https://repo1.maven.org/maven2/org/projectlombok/lombok/1.18.36/lombok-1.18.36.jar";
              sha256 = "sha256-c7awW2otNltwC6sI0w+U3p0zZJC8Cszlthgf70jL8Y4=";
            };
            settings = {
              java = {
                home = "${pkgs.jdk21_headless}";
                configuration.runtimes = [
                  {
                    name = "JavaSE-11";
                    path = "${pkgs.jdk11_headless}";
                  }
                  {
                    name = "JavaSE-17";
                    path = "${pkgs.jdk17_headless}";
                  }
                  {
                    name = "JavaSE-21";
                    path = "${pkgs.jdk21_headless}";
                  }
                ];
                format.settings.url = "file://${config.xdg.configHome}/nvim/lsp/jdtls/formatter.xml";
              };
            };
          };
        };
      in
      ''
        vim.g.nix = vim.fn.json_decode('${builtins.toJSON globals}')
        require('user')
      '';

    plugins = with pkgs.unstable.vimPlugins; [ lazy-nvim ];

    extraPackages = with pkgs.unstable; [

      # language servers
      clojure-lsp
      emmet-language-server
      gopls
      graphql-language-service-cli
      harper-ls
      helm-ls
      jdt-language-server
      libclang
      lua-language-server
      nil
      terraform-ls
      tflint
      typescript
      vscode-langservers-extracted
      vtsls
      yaml-language-server

      # formatters/linters
      nixfmt-rfc-style
      joker
      prettierd
      shfmt
      stylua
      taplo

      # misc
      gnumake
      clang # for compiling tree-sitter parsers
    ];
  };

  home.activation.lazy-sync = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    ${config.programs.neovim.finalPackage}/bin/nvim --headless "+Lazy! restore" +qa
  '';

  home.packages = with pkgs.unstable; [
    # test runners
    cargo-nextest # for rouge8/neotest-rust
  ];

  xdg.configFile = {
    "nvim/after".source = config.lib.file.mkFlakeSymlink ./after;
    "nvim/lazy-lock.json".source = config.lib.file.mkFlakeSymlink ./lazy-lock.json;
    "nvim/lsp".source = config.lib.file.mkFlakeSymlink ./lsp;
    "nvim/lua".source = config.lib.file.mkFlakeSymlink ./lua;
  };

  programs.zsh.shellAliases.vimdiff = "nvim -d";

  programs.zsh.initExtra =
    # bash
    ''
      if typeset -f nvim >/dev/null; then
        unset -f nvim
      fi
      _nvim=$(which nvim)
      nvim() {
        if [[ -z "$@" ]]; then
          if [[ -f "./Session.vim" ]]; then
            $_nvim -c ':silent source Session.vim' -c 'lua vim.g.savesession = true'
          else
            $_nvim
          fi
        else
          $_nvim "$@"
        fi
      }
    '';

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
