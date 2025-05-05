{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.firefox = {
    enable = true;
    # TODO: remove once https://github.com/NixOS/nixpkgs/pull/400246
    package = if pkgs.stdenv.isDarwin then null else pkgs.unstable.firefox-devedition-bin;
    # name must start with "dev-edition-"? https://github.com/nix-community/home-manager/issues/4703
    policies = {
      ManagedBookmarks = builtins.toJSON [
        {
          toplevel_name = "My Managed Bookmarks";
          children = [
            {
              keyword = "hmo";
              name = "Home-Manager Options";
              tags = [ "nix" ];
              url = "https://searchix.alanpearce.eu/options/home-manager/search?query=%s";
            }
            {
              keyword = "dwo";
              name = "Nix-Darwin Options";
              tags = [ "nix" ];
              url = "https://searchix.alanpearce.eu/options/darwin/search?query=%s";
            }
            {
              keyword = "nxo";
              name = "NixOS Options";
              tags = [ "nix" ];
              url = "https://search.nixos.org/options?channel=unstable&query=%s";
            }
            {
              keyword = "nxp";
              name = "Nix Packages";
              tags = [ "nix" ];
              url = "https://search.nixos.org/packages?channel=unstable&query=%s";
            }
          ];
        }
      ];
    };
    profiles.dev-edition-default = {
      extensions.packages = [ pkgs.firefox-aws-cli-sso ];
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
