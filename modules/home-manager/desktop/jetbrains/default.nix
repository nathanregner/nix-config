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
in
{
  options.programs.jetbrains = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };

    tools = mkOption {
      default = {
        datagrip = {
          toolboxFolder = "datagrip";
          darwinAppGlob = "IntelliJ\\ IDEA\\ Ultimate*.app";
          plugins = [ ];
        };
        idea = {
          toolboxFolder = "intellij-idea-ultimate";
          darwinAppGlob = "DataGrip\\*.app";
          plugins = [ ];
        };
        rider = {
          toolboxFolder = "rider";
          darwinAppGlob = "Rider*.app";
          plugins = [ ];
        };
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

  config = lib.mkIf cfg.enable (
    lib.mkMerge (
      [
        {
          home.file.".ideavimrc".source = config.lib.file.mkFlakeSymlink ./ideavimrc;

          home.packages = lib.optionals pkgs.stdenv.isLinux [
            pkgs.unstable.jetbrains-toolbox
          ];
        }
      ]
      ++ lib.mapAttrsToList (toolName: toolCfg: {
        home.packages = [
          (pkgs.writeShellScriptBin toolName (
            if pkgs.stdenv.isDarwin then
              "open -na ~/Applications/${toolCfg.darwinAppGlob}/Contents/MacOS/${toolName} --args"
            else
              ''nohup ~/.local/share/JetBrains/Toolbox/apps/${toolCfg.toolboxFolder}/bin/${toolName} "$@" &> /dev/null & disown %%''
          ))
        ];

        xdg.configFile = (
          let
            commonConfig = listFilesRecursive ./config/common;
            appConfig = listFilesRecursive (./config + "/${toolName}");
            prefix = "JetBrains/${toolName}/config";
          in
          lib.listToAttrs (
            map (file: {
              name = "${prefix}/${file.name}";
              value = {
                source = config.lib.file.mkFlakeSymlink file.path;
                force = true;
              };
            }) (commonConfig ++ appConfig)
            ++ map (plugin: {
              name = "${prefix}/plugins/${plugin.name}.jar";
              value = {
                source = "${plugin}";
                force = true;
              };
            }) toolCfg.plugins
          )
        );
      }) tools
    )
  );
}
