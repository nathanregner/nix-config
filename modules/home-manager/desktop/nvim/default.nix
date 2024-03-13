{ config, pkgs, ... }:
{
  imports = [ ./tools ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = ''
      vim.g.lombok_jar = '${
        pkgs.fetchurl {
          url = "https://repo1.maven.org/maven2/org/projectlombok/lombok/1.18.34/lombok-1.18.34.jar";
          sha256 = "06mqsj33x0hxxd73gxw05i1np7khhfqwdg7w0wdis92nzwm6nzf2";
        }
      }'
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
    "nvim/lua".source = config.lib.file.mkFlakeSymlink ./lua;
    "nvim/after".source = config.lib.file.mkFlakeSymlink ./after;
    "nvim/lazy-lock.json".source = config.lib.file.mkFlakeSymlink ./lazy-lock.json;
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
