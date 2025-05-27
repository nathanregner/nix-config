{
  config,
  pkgs,
  ...
}:
{
  home.file.".hammerspoon" = {
    source = ./hammerspoon;
    recursive = true;
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
