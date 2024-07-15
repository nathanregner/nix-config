{
  programs.firefox = {
    profiles.default = {

      # extensions = [
      #   (pkgs.stdenv.mkDerivation {
      #     name = "firefox-extension-ublock-origin";
      #     src = ./extensions;
      #     dontBuild = true;
      #     installPhase = ''
      #     '';
      #   })
      # ];

      settings = {
        extensions.autoDisableScopes = 0;
      };
    };
  };
}
