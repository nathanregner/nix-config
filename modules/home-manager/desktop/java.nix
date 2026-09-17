{ pkgs, lib, ... }:
let
  plugin = pkgs.local.versions-maven-plugin;
  inherit (plugin) version;
  modules = [
    "versions"
    "versions-api"
    "versions-model"
    "versions-model-report"
    "versions-common"
    "versions-enforcer"
    "versions-maven-plugin"
  ];
in
{
  home.file = lib.listToAttrs (
    map (
      m:
      lib.nameValuePair ".m2/repository/org/codehaus/mojo/${m}/${version}" {
        source = "${plugin}/repository/org/codehaus/mojo/${m}/${version}";
        recursive = true;
      }
    ) modules
  );
}
