{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [ ./tools ];

  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig = ''
      vim.g.copilot_node_command = '${pkgs.unstable.nodejs_20}/bin/node'
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
      helm-ls
      lua-language-server
      # FIXME: nix 2.23 fails to build on darwin
      (nil.override {
        nixVersions = {
          latest = pkgs.unstable.nixVersions.nix_2_22;
        };
      })
      nodePackages_latest.graphql-language-service-cli
      terraform-ls
      vscode-langservers-extracted
      yaml-language-server
      pkgs.jdtls
      pkgs.vtsls

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

  programs.zsh.initExtra = ''
    if typeset -f nvim > /dev/null; then
      unset -f nvim
    fi
    _nvim=$(which nvim)
    nvim () {
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
