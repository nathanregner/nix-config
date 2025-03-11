{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.firefox = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.unstable.firefox-devedition;
    # name must start with "dev-edition-"? https://github.com/nix-community/home-manager/issues/4703
    profiles.dev-edition-default = {
      # FIXME: doesn't auto-install
      extensions = [ pkgs.aws-cli-sso ];
      settings = {
        "browser.aboutConfig.showWarning" = false;

        "extensions.autoDisableScopes" = 0;
        "xpinstall.signatures.required" = false;
      };
    };
  };

  home.packages = [
    (pkgs.runCommand "firefox" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      makeWrapper ${lib.getExe config.programs.firefox.package} $out/bin/firefox
    '')
  ];
}
