{ inputs, buildNpmPackage }:
buildNpmPackage {
  pname = "mainsail";
  version = "develop";
  src = inputs.mainsail;

  npmDepsHash = "sha256-oAr7b7YwozPB2m+YcXtd/vCzBEYToYBnYU7uk1Z8tGY=";

  CYPRESS_INSTALL_BINARY = "0";

  buildPhase = ''
    npx vite build
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mainsail
    cp -r dist/* $out/share/mainsail

    runHook postInstall
  '';
}
