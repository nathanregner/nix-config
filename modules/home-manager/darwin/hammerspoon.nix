{
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkFlakeSymlink;
in
{
  home.file = {
    ".hammerspoon/Spoons" = {
      source = pkgs.symlinkJoin {
        name = "Spoons";
        paths = [
          ./hammerspoon/Spoons
          "${pkgs.local.hammerspoon-spoons}"
        ];
      };
      force = true;
    };
    ".hammerspoon/init.lua" = {
      source = mkFlakeSymlink ./hammerspoon/init.lua;
      force = true;
    };
    ".hammerspoon/autolayout.lua" = {
      source = mkFlakeSymlink ./hammerspoon/autolayout.lua;
      force = true;
    };
  };

  home.packages = [ pkgs.local.hammerspoon ];

  launchd.agents."hammerspoon" = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.local.hammerspoon}/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon"
      ];
      KeepAlive.SuccessfulExit = false;
      WatchPaths = [
        "${config.home.homeDirectory}/.hammerspoon"
      ];
    };
  };
}
