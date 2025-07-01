{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.neovim.modules.java;
  formatterConfigPath = "nvim/lsp/jdtls/formatter.xml";
in
{
  options.programs.neovim.modules.java = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    formatterConfig = mkOption {
      type = types.path;
      default = config.lib.file.mkFlakeSymlink ./cb_eclipse-java-google-style.xml;
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      extraPackages = with pkgs.unstable; [
        jdt-language-server
        local.spring-javaformat
      ];

      lua.globals.jdtls = {
        lombok = pkgs.local.lombok;
        settings = {
          java = {
            format.settings.url = "file://${config.xdg.configHome}/${formatterConfigPath}";
          };
        };
      };
    };

    programs.git.ignores = [
      ".classpath"
      ".eclipse"
      ".factorypath"
      ".project"
      ".settings"
    ];

    xdg.configFile = {
      "nvim/after/ftplugin/java.lua" = {
        source = config.lib.file.mkFlakeSymlink ./java.lua;
        force = true;
      };
      ${formatterConfigPath} = {
        source = cfg.formatterConfig;
        force = true;
      };
    };

    home.file.".gradle/init.d/add-versions-plugin.init.gradle.kts".source =
      ./add-versions-plugin.init.gradle.kts;
  };
}
