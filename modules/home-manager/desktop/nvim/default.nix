{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.neovim;
in
{
  imports = [ ./modules ];

  options = {
    programs.neovim = {
      lua.globals = mkOption {
        type = types.submodule {
          freeformType = types.attrsOf types.anything;
          options = {
            rtp = mkOption {
              type = types.listOf types.str;
            };
          };
        };
      };
    };
  };

  config = {
    programs.neovim = {
      enable = true;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      defaultEditor = true;
      extraConfig = builtins.readFile ./init.vim;
      extraLuaConfig = ''
        vim.g.nix = vim.fn.json_decode('${builtins.toJSON cfg.lua.globals}')
        require('user')
      '';

      plugins = with pkgs.unstable.vimPlugins; [ lazy-nvim ];

      lua.globals = {
        luasnip.dir = "${pkgs.unstable.vimPlugins.luasnip}";
        neotest-jest.dir = "${pkgs.unstable.vimPlugins.neotest-jest.overrideAttrs {
          patches = [
            (pkgs.fetchpatch2 {
              url = "https://patch-diff.githubusercontent.com/raw/nvim-neotest/neotest-jest/pull/141.patch";
              hash = "sha256-IxgnjB2TzqLi/TFGruR52ia3R/AnrgJAZKAqY5lIX4A=";
            })
          ];
        }}";
      };

      extraPackages = builtins.attrValues (
        {
          # language servers
          inherit (pkgs.unstable)
            bash-language-server
            emmet-language-server
            gopls
            graphql-language-service-cli
            harper
            helm-ls
            libclang
            lua-language-server
            nil
            nixd
            terraform-ls
            tflint
            vscode-langservers-extracted
            vtsls
            yaml-language-server
            ;

          # formatters/linters
          inherit (pkgs.unstable)
            nginx-config-formatter
            nixfmt-rfc-style
            prettierd
            shfmt
            stylua
            taplo
            ;

          inherit (pkgs.unstable) git;
        }
        // lib.optionalAttrs pkgs.stdenv.isLinux {
          inherit (pkgs.unstable)
            inotify-tools
            ;
        }
      );
    };

    home.packages = with pkgs.unstable; [
      # test runners
      cargo-nextest # for rouge8/neotest-rust
    ];

    xdg.configFile =
      {
        "nvim/lazy-lock.json" = {
          source = config.lib.file.mkFlakeSymlink ./lazy-lock.json;
          force = true;
        };
        "nvim/lua" = {
          source = config.lib.file.mkFlakeSymlink ./lua;
          force = true;
        };
        "nvim/snippets" = {
          source = config.lib.file.mkFlakeSymlink ./snippets;
          force = true;
        };
      }
      // lib.listToAttrs (
        builtins.map (source: {
          name = "nvim/after/ftplugin/${builtins.baseNameOf source}";
          value = {
            source = config.lib.file.mkFlakeSymlink source;
            force = true;
          };
        }) (lib.filesystem.listFilesRecursive ./after/ftplugin)
      );

    programs.zsh.shellAliases.vimdiff = "nvim -d";

    # https://github.com/jesseduffield/lazygit/wiki/Custom-Commands-Compendium
    programs.lazygit.settings.customCommands = [
      {
        key = "M";
        command = "nvim -c DiffviewOpen .";
        description = "Open diffview.nvim";
        context = "files";
        loadingText = "opening diffview.nvim";
        output = "terminal";
      }
    ];
  };
}
