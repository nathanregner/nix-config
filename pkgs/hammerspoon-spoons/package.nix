{
  fetchFromGitHub,
  lib,
  nix-update-script,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "hammerspoon-spoons";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "Hammerspoon";
    repo = "Spoons";
    rev = "e5b871250346c3fe93bac0d431fc75f6f0e2f92a";
    hash = "sha256-5HPH8h16sJSLTASHWxLM4XhcZ/uyF6PaMhkW6T+L6gg=";
    sparseCheckout = [
      "Source/EmmyLua.spoon"
    ];
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  sourceRoot = "Source";

  installPhase = ''
    cp -r $src/Source $out
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    homepage = "https://www.hammerspoon.org/Spoons/";
    platforms = lib.platforms.darwin;
  };
}
