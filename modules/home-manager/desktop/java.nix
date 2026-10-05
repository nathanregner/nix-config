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
  home.file =
    lib.listToAttrs (
      map (
        m:
        lib.nameValuePair ".m2/repository/org/codehaus/mojo/${m}/${version}" {
          source = "${plugin}/repository/org/codehaus/mojo/${m}/${version}";
          recursive = true;
        }
      ) modules
    )
    // {
      # stable path for env/spring-boot.sh's JDBC_SPY -javaagent
      ".local/share/java/log4jdbc-agent.jar".source =
        "${pkgs.local.log4jdbc-agent}/share/java/log4jdbc-agent.jar";
    };
}
