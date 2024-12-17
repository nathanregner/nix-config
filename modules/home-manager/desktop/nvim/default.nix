{
  config,
  pkgs,
  ...
}:
let
  parserInstallDir = "nvim/nvim-treesitter";
in
{
  imports = [ ./tools ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./init.vim;
    extraLuaConfig =
      let
        globals = {
          # rtp = pkgs.linkFarm "rtp" builtins.mapAttrs (drv: {
          #   name = drv.pname;
          #   path = drv;
          # }) pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars.passthru.dependencies;

          # TODO: https://github.com/nvim-treesitter/nvim-treesitter/blob/master/README.md#changing-the-parser-install-directory
          nvim_treesitter = {
            dir = "${pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars}";
            parser_install_dir = "${config.xdg.dataHome}/${parserInstallDir}";
          };
          blink_cmp.dir = "${pkgs.unstable.blink-cmp}";
          jdtls = {
            lombok = pkgs.fetchurl {
              url = "https://repo1.maven.org/maven2/org/projectlombok/lombok/1.18.36/lombok-1.18.36.jar";
              sha256 = "sha256-c7awW2otNltwC6sI0w+U3p0zZJC8Cszlthgf70jL8Y4=";
            };
            settings = {
              java = {
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

    plugins = with pkgs.unstable.vimPlugins; [
      lazy-nvim
    ];

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

  xdg.dataFile = builtins.listToAttrs (
    builtins.map (
      grammar:
      let
        language = builtins.elemAt (builtins.match "vimplugin-treesitter-grammar-(.*)" grammar.name) 0;
      in
      {
        name = "${parserInstallDir}/parser/${language}.so";
        value = {
          source = "${grammar}/parser/${language}.so";
          force = true;
        };
      }
    ) pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars.passthru.dependencies
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
}
