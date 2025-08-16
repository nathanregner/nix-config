{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.neovim.modules.java;
  formatterCfg = "nvim/lsp/jdtls/formatter.xml";
in
{
  options = {
    programs.neovim.modules.java.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      extraPackages = with pkgs.unstable; [
        jdt-language-server
      ];

      lua.globals.jdtls = {
        lombok = pkgs.fetchurl {
          url = "https://repo1.maven.org/maven2/org/projectlombok/lombok/1.18.36/lombok-1.18.36.jar";
          sha256 = "sha256-c7awW2otNltwC6sI0w+U3p0zZJC8Cszlthgf70jL8Y4=";
        };
        settings = {
          java = {
            format.settings.url = "file://${config.xdg.configHome}/${formatterCfg}";
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
      ${formatterCfg} = {
        source = config.lib.file.mkFlakeSymlink ./formatter.xml;
        force = true;
      };
    };

    home.file.".gradle/init.d/add-versions-plugin.init.gradle.kts" = {
      source = ./add-versions-plugin.init.gradle.kts;
      force = true;
    };
  };
}
