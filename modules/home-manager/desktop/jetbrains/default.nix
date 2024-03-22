{ config, lib, ... }:
let
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
        };
      }
    ) (commonConfig ++ appConfig);
in
{
  config = {
    home.file.".ideavimrc".source = config.lib.file.mkFlakeSymlink ./ideavimrc;

    xdg.configFile = lib.mkMerge (
      builtins.concatMap linkConfigFiles [
        "idea"
        "datagrip"
      ]
    );
  };
}
