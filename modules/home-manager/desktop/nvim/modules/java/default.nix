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
        # https://projectlombok.org/changelog
        lombok = pkgs.fetchurl {
          url = "https://repo1.maven.org/maven2/org/projectlombok/lombok/1.18.38/lombok-1.18.38.jar";
          sha256 = "sha256-Hh5CfDb/Y8RP0w7yktnnc+oxVEYKtiZdP+1+b1vFD7k=";
        };
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
