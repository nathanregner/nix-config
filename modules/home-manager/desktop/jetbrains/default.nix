{ config, lib, ... }:
let
  files = prefix:
    (builtins.map ({ name, value }: { "JetBrains/${prefix}/${name}" = value; })
      (lib.attrsToList {
        codestyles = {
          source = config.lib.file.mkFlakeSymlink ./config/codestyles;
          recursive = true;
        };
        extensions = {
          source = config.lib.file.mkFlakeSymlink ./config/extensions;
          recursive = true;
        };
        keymaps.source = config.lib.file.mkFlakeSymlink ./config/keymaps;
        options = {
          source = config.lib.file.mkFlakeSymlink ./config/options;
          recursive = true;
        };
        templates.source = config.lib.file.mkFlakeSymlink ./config/templates;
      }));
in {
  home.file.".ideavimrc".source = config.lib.file.mkFlakeSymlink ./ideavimrc;

  xdg.configFile = lib.mkMerge ((files "idea") ++ (files "datagrip"));
}

