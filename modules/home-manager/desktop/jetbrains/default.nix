{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.jetbrains;

  listFilesRecursive =
    root:
    builtins.map (file: {
      name = (lib.removePrefix "./" (toString (lib.path.removePrefix (root) file)));
      path = file;
    }) (lib.filesystem.listFilesRecursive root);

  linkConfigFiles =
    appName:
    let
      commonConfig = (listFilesRecursive ./config/common);
      appConfig = (listFilesRecursive (./config + "/${appName}"));
    in
    builtins.map (
      { name, path }:
      {
        "JetBrains/${appName}/config/${name}" = {
          source = config.lib.file.mkFlakeSymlink path;
          force = true;
        };
      }
    ) (commonConfig ++ appConfig);
in
{
  options.programs.jetbrains = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".ideavimrc".source = config.lib.file.mkFlakeSymlink ./ideavimrc;

    home.packages = lib.optionals pkgs.stdenv.isLinux [
      pkgs.unstable.jetbrains-toolbox
    ];

    programs.zsh.shellAliases =
      if pkgs.stdenv.isLinux then
        {
          idea = "~/.local/share/JetBrains/Toolbox/apps/intellij-idea-ultimate/bin/idea";
          datagrip = "~/.local/share/JetBrains/Toolbox/apps/datagrip/bin/datagrip";
        }
      else
        {
          idea = "open -na ~/Applications/IntelliJ\\ IDEA\\ Ultimate*.app/Contents/MacOS/datagrip --args";
          datagrip = "open -na ~/Applications/DataGrip\\*.app/Contents/MacOS/datagrip --args";
        };

    xdg.configFile = lib.mkMerge (
      builtins.concatMap linkConfigFiles [
        "idea"
        "datagrip"
      ]
    );
  };
}
