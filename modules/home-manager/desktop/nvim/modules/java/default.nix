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
      default = false;
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      extraPackages = with pkgs.unstable; [
        jdt-language-server
        local.spring-javaformat
      ];

      lua.globals.jdtls = {
        lombok = "${pkgs.lombok}/share/java/lombok.jar";
        settings = {
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
  };
}
