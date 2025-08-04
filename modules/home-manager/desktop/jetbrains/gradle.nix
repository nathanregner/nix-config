{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.local.programs.jetbrains.gradle;
in
{
  options.local.programs.jetbrains.gradle = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.local.programs.jetbrains.enable;
    };

    package = lib.mkPackageOption pkgs.unstable "gradle" { };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."JetBrains/idea/config/options/gradle.default.xml" = {
      source = pkgs.writeText "gradle-settings.xml" ''
        <application>
          <component name="GradleDefaultProjectSettings">
            <option name="distributionType" value="LOCAL" />
            <option name="gradleHome" value="${cfg.package}/lib/gradle" />
          </component>
        </application>
      '';
      force = true;
    };
  };
}
