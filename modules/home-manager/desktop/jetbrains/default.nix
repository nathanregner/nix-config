{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    concatLists
    filesystem
    map
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    optionals
    path
    types
    ;

  cfg = config.programs.jetbrains;

  listFilesRecursive =
    root:
    map (file: {
      name = lib.removePrefix "./" (toString (path.removePrefix root file));
      path = file;
    }) (filesystem.listFilesRecursive root);

  linkConfigFiles =
    appName:
    { plugins, ... }:
    let
      commonConfig = listFilesRecursive ./config/common;
      appConfig = listFilesRecursive (./config + "/${appName}");
    in
    (map (
      { name, path }:
      {
        "JetBrains/${appName}/config/${name}" = {
          source = config.lib.file.mkFlakeSymlink path;
          force = true;
        };
      }
    ) (commonConfig ++ appConfig))
    ++ map (plugin: {
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
            plugins = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    home.file.".ideavimrc".source = config.lib.file.mkFlakeSymlink ./ideavimrc;

    home.packages = optionals pkgs.stdenv.isLinux [
      pkgs.unstable.jetbrains-toolbox
    ];

    programs.jetbrains.tools = {
      datagrip = { };
      idea = { };
    };

    # TODO: move to cfg.tools
    programs.zsh.shellAliases =
      if pkgs.stdenv.isLinux then
        {
          idea = "~/.local/share/JetBrains/Toolbox/apps/intellij-idea-ultimate/bin/idea";
          datagrip = "~/.local/share/JetBrains/Toolbox/apps/datagrip/bin/datagrip";
        }
      else
        {
          idea = "open -na ~/Applications/IntelliJ\\ IDEA\\ Ultimate*.app/Contents/MacOS/idea --args";
          datagrip = "open -na ~/Applications/DataGrip\\*.app/Contents/MacOS/datagrip --args";
        };

    xdg.configFile = mkMerge (concatLists (mapAttrsToList linkConfigFiles cfg.tools));
  };
}
