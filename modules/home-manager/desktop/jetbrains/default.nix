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
      let
        launchDetached =
          name: bin:
          pkgs.writeShellScriptBin name ''
            nohup ${bin} "$@" &> /dev/null & disown %%
          '';
      in
      [
        pkgs.unstable.jetbrains-toolbox
        (launchDetached "idea" "~/.local/share/JetBrains/Toolbox/apps/intellij-idea-ultimate/bin/idea")
        (launchDetached "datagrip" "~/.local/share/JetBrains/Toolbox/apps/datagrip/bin/datagrip")
      ]
    );

    programs.jetbrains.tools = {
      datagrip = { };
      idea = { };
    };

    # TODO: move to cfg.tools
    programs.zsh.shellAliases = lib.optionalAttrs pkgs.stdenv.isDarwin {
      idea = "open -na ~/Applications/IntelliJ\\ IDEA\\ Ultimate*.app/Contents/MacOS/idea --args";
      datagrip = "open -na ~/Applications/DataGrip\\*.app/Contents/MacOS/datagrip --args";
    };

    xdg.configFile = lib.mkMerge (lib.concatLists (lib.mapAttrsToList linkConfigFiles cfg.tools));
  };
}
