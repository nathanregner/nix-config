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
        spring-javaformat
      ];

      lua.globals.jdtls = {
        lombok = pkgs.fetchurl {
          url = "https://repo1.maven.org/maven2/org/projectlombok/lombok/1.18.36/lombok-1.18.36.jar";
          sha256 = "sha256-c7awW2otNltwC6sI0w+U3p0zZJC8Cszlthgf70jL8Y4=";
        };
        settings = {
          java = {
            format.settings.url = "file://${config.xdg.configHome}/${formatterConfigPath}";
          };
        };
      };
    };

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
  };
}
