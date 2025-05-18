{
  jq,
  stdenvNoCC,
  web-ext,
}:

{ pname, ... }@args:

stdenvNoCC.mkDerivation (
  args
  // {
    nativeBuildInputs = [
      jq
      web-ext
    ];

    patchPhase = ''
      runHook prePatch
      jq '.browser_specific_settings.gecko.id = "${pname}"' manifest.json >manifest.temp.json
      mv manifest.temp.json manifest.json
      runHook postPatch
    '';

    buildPhase = ''
      runHook preBuild
      web-ext build
      runHook postBuild
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
)
