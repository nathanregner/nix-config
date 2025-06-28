{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.firefox = {
    enable = true;
    package = pkgs.unstable.firefox-devedition;
    # name must start with "dev-edition-"? https://github.com/nix-community/home-manager/issues/4703
    profiles.dev-edition-default = {
      extensions.packages = [ pkgs.local.firefox-extensions.aws-cli-sso ];
      settings = {
        "browser.aboutConfig.showWarning" = false;

        "extensions.autoDisableScopes" = 0;
        "xpinstall.signatures.required" = false;
      };
    };
  };

  home.packages = lib.optionals (!pkgs.stdenv.isDarwin) [
    (pkgs.runCommand "firefox" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      makeWrapper ${lib.getExe config.programs.firefox.package} $out/bin/firefox
    '')
  ];
}
