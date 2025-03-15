{ stdenvNoCC, web-ext }:

# https://gitlab.com/rycee/nur-expressions/-/blob/master/pkgs/firefox-addons/default.nix

stdenvNoCC.mkDerivation rec {
  pname = "aws-cli-sso";
  version = "0.0.0";
  src = ./src;

  nativeBuildInputs = [ web-ext ];

  buildPhase = ''
    web-ext build
  '';

  passthru = {
    addonId = pname;
  };

  installPhase = ''
    dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
    mkdir -p "$dst"
    install -v -m644 web-ext-artifacts/* "$dst/${pname}.xpi"
  '';
}
