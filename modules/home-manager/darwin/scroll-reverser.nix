{ pkgs, ... }:
{
  targets.darwin.defaults."com.pilotmoon.scroll-reverser" = {
    DiscreteScrollStepSize = 10;
    HasRequestedAccessibilityPermission = 1;
    HasRequestedInputMonitoringPermission = 1;
    HasRunBefore = 1;
    InvertScrollingOn = 1;
    ReverseTrackpad = 0;
    SUHasLaunchedBefore = 1;
    ShowDiscreteScrollOptions = 1;
  };

  home.packages = [ pkgs.local.scroll-reverser ];
}
