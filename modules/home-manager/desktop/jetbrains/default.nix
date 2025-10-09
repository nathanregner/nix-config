{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.programs.jetbrains;

  listFilesRecursive =
    root:
    map (file: {
      name = lib.removePrefix "./" (toString (lib.path.removePrefix root file));
      path = file;
    }) (lib.filesystem.listFilesRecursive root);

  linkConfigFiles =
    appName:
    { plugins, ... }:
    let
      commonConfig = listFilesRecursive ./config/common;
      appConfig = listFilesRecursive (./config + "/${appName}");
    in
    (builtins.map (
      { name, path }:
      {
        "JetBrains/${appName}/config/${name}" = {
          source = config.lib.file.mkFlakeSymlink path;
          force = true;
        };
      }
    ) (commonConfig ++ appConfig))
    ++ builtins.map (plugin: {
      "JetBrains/${appName}/config/plugins/${plugin.name}.jar" = {
        source = "${plugin}";
        force = true;
      };
    }) plugins;
in
{
  options.programs.jetbrains = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    tools = mkOption {
      default = {
      };
      type = types.attrsOf (
        types.submodule {
          options = {
            toolboxFolder = mkOption {
              type = types.str;
            };
            darwinAppGlob = mkOption {
              type = types.str;
            };
            plugins = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".ideavimrc".source = config.lib.file.mkFlakeSymlink ./ideavimrc;

    home.packages = lib.optionals pkgs.stdenv.isLinux (
      [
        pkgs.unstable.jetbrains-toolbox
      ]
      ++ (lib.mapAttrsToList (
        name: cfg:
        let
          launchDetached =
            name: bin:
            pkgs.writeShellScriptBin name ''
              nohup ${bin} "$@" &> /dev/null & disown %%
            '';
        in
        launchDetached name "~/.local/share/JetBrains/Toolbox/apps/${cfg.toolboxFolder}/bin/${name}"
      ) cfg.tools)
    );

    programs.jetbrains.tools = {
      datagrip = {
        toolboxFolder = "datagrip";
        darwinAppGlob = "DataGrip\\*.app";
      };
      idea = {
        toolboxFolder = "intellij-idea-ultimate";
        darwinAppGlob = "IntelliJ\\ IDEA\\ Ultimate*.app";
      };
      rider = {
        toolboxFolder = "rider";
        darwinAppGlob = "Rider*.app";
      };
    };

    # TODO: move to cfg.tools
    programs.zsh.shellAliases = lib.optionalAttrs pkgs.stdenv.isDarwin (
      builtins.mapAttrs (
        name: cfg: "open -na ~/Applications/${cfg.darwinAppGlob}/Contents/MacOS/${name} --args"
      ) cfg.tools
    );

    xdg.configFile = lib.mkMerge (lib.concatLists (lib.mapAttrsToList linkConfigFiles cfg.tools));
  };
}
