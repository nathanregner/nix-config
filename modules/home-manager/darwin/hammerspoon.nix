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

  home.packages = [ pkgs.hammerspoon ];

  launchd.agents."hammerspoon" = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.hammerspoon}/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon"
      ];
      KeepAlive.SuccessfulExit = false;
      WatchPaths = [
        "${config.home.homeDirectory}/.hammerspoon"
      ];
    };
  };
}
