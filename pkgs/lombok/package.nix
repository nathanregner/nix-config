{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  jdk,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lombok";
  version = "1.18.44";

  src = fetchurl {
    url = "https://projectlombok.org/downloads/lombok-${finalAttrs.version}.jar";
    hash = "sha256-xukb/cNYux77Je4YXpWq+bYABD5fgdA712rvwBA1v4Y=";
  };

  nativeBuildInputs = [ makeWrapper ];

  outputs = [
    "out"
    "bin"
  ];

  buildCommand = ''
    mkdir -p $out/share/java
    cp $src $out/share/java/lombok.jar

    makeWrapper ${jdk}/bin/java $bin/bin/lombok \
      --add-flags "-cp ${jdk}/lib/openjdk/lib/tools.jar:$out/share/java/lombok.jar" \
      --add-flags lombok.launch.Main
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "v(.*)"
      "--url"
      "https://projectlombok.org/changelog"
    ];
  };

  meta = {
    description = "Library that can write a lot of boilerplate for your Java project";
    mainProgram = "lombok";
    platforms = lib.platforms.all;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.mit;
    homepage = "https://projectlombok.org/";
  };
})
