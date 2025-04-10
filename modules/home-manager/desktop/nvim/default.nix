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
      # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      defaultEditor = true;
      extraConfig = builtins.readFile ./init.vim;
      extraLuaConfig = ''
        vim.g.nix = ${lib.generators.toLua { } cfg.lua.globals}
        require('user')
      '';

      plugins = with pkgs.unstable.vimPlugins; [ lazy-nvim ];

      extraLuaPackages =
        let
          propagateBuildInputs =
            drvs:
            builtins.map (i: i.val) (
              builtins.genericClosure {
                startSet = builtins.map (drv: {
                  key = drv.outPath;
                  val = drv;
                }) drvs;
                operator =
                  { val, ... }:
                  builtins.map (drv: {
                    key = drv.outPath;
                    val = drv;
                  }) (val.propagatedBuildInputs or [ ]);
              }
            );
        in
        ps: propagateBuildInputs [ ps.busted ];

      lua.globals = {
        luasnip.dir = "${pkgs.unstable.vimPlugins.luasnip}";
      };

      extraPackages = builtins.attrValues {
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
          nixfmt-rfc-style
          prettierd
          shfmt
          stylua
          taplo
          ;
      };
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
  };
}
