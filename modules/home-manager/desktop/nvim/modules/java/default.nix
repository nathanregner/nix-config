{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.neovim.modules.java;
in
{
  options.programs.neovim.modules.java = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

  };

  config = mkIf cfg.enable {
    programs.neovim = {
      extraPackages = with pkgs.unstable; [
        local.spring-javaformat
        local.intellij-server
      ];

      lua.globals = {
        junit_jar = pkgs.fetchurl {
          url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.1/junit-platform-console-standalone-1.10.1.jar";
          hash = "sha256-tC6qU9E1dtF9tfuLKAcipq6eNtr5X0JivG6W1Msgcl8=";
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
    };

    home.file.".gradle/init.d/add-versions-plugin.init.gradle.kts" = {
      source = ./add-versions-plugin.init.gradle.kts;
      force = true;
    };

    home.file.".m2/mvnd.properties" = {
      source = ./mvnd.properties;
      force = true;
    };
  };
}
