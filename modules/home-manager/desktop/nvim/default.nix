{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) types options;
  cfg = config.programs.neovim;
in
{
  imports = [ ./modules ];

  options = {
    programs.neovim = {
      lua.globals = options.mkOption {
        type = types.submodule {
          freeformType = types.attrsOf types.anything;
          options = {
            rtp = options.mkOption {
              type = types.listOf (
                types.oneOf [
                  types.path
                  types.string
                ]
              );
            };
          };
        };
      };
    };
  };

  config = {
    programs.neovim = {
      enable = true;
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
        blink_cmp.dir = "${pkgs.unstable.blink-cmp}";
        luasnip.dir = "${pkgs.unstable.vimPlugins.luasnip}";
        # rtp =
        #   let
        #     inherit (config.programs.neovim.finalPackage.passthru.unwrapped) lua;
        #   in
        #   [
        #     lua.pkgs.busted
        #     # (pkgs.runCommand "busted-lua" { } ''
        #     #   mkdir -p $out/lua
        #     #   cp -r ${lua.pkgs.busted}/share/lua/*/* $out/lua
        #     # '')
        #   ];
      };

      extraPackages = with pkgs.unstable; [

        # language servers
        emmet-language-server
        gopls
        pkgs.unstable.nodePackages_latest.graphql-language-service-cli
        harper-ls
        helm-ls
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
        prettierd
        shfmt
        stylua
        taplo
      ];
    };

    home.activation.lazy-sync = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      ${config.programs.neovim.finalPackage}/bin/nvim --headless "+Lazy! restore" +qa || echo "Failed to sync plugins"
    '';

    home.packages = with pkgs.unstable; [
      # test runners
      cargo-nextest # for rouge8/neotest-rust
    ];

    xdg.configFile =
      {
        "nvim/after/queries".source = config.lib.file.mkFlakeSymlink ./after/queries;
        "nvim/lazy-lock.json".source = config.lib.file.mkFlakeSymlink ./lazy-lock.json;
        "nvim/lua".source = config.lib.file.mkFlakeSymlink ./lua;
      }
      // lib.listToAttrs (
        builtins.map (source: {
          name = "nvim/after/${builtins.baseNameOf source}";
          value = {
            source = config.lib.file.mkFlakeSymlink source;
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
