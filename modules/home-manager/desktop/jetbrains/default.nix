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
    enable = lib.mkEnableOption "Link JetBrains configs and enable jetbrains-toolbox";
  };

  config = lib.mkIf cfg.enable {
    home.file.".ideavimrc".source = config.lib.file.mkFlakeSymlink ./ideavimrc;

    home.packages = lib.optionals pkgs.stdenv.isLinux [
      pkgs.jetbrains-toolbox
    ];

    programs.zsh.shellAliases =
      if pkgs.stdenv.isLinux then
        {
          idea = "~/.local/share/JetBrains/Toolbox/apps/intellij-idea-ultimate/bin/idea";
          datagrip = "~/.local/share/JetBrains/Toolbox/apps/datagrip/bin/datagrip";
        }
      else
        {
          idea = "open -a /Users/nathan.regner/Applications/IntelliJ\\ IDEA\\ Ultimate\\ *.app";
          datagrip = "open -a /Users/nathan.regner/Applications/Datagrip\\ *.app";
        };

    xdg.configFile = lib.mkMerge (
      builtins.concatMap linkConfigFiles [
        "idea"
        "datagrip"
      ]
    );
  };
}
