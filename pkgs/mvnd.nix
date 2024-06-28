{
  lib,
  stdenvNoCC,
  fetchzip,
  jdk,
  makeWrapper,
}:

assert jdk != null;

let
  version = "1.0.1";
  sources = {
    x86_64-linux = {
      url = "https://downloads.apache.org/maven/mvnd/${version}/maven-mvnd-${version}-linux-amd64.zip";
      hash = "sha256-PaPBKf1CCzO1QA98jl3zE2OfldfQOl/A2iZkeUllq+k=";
    };
    x86_64-darwin = {
      url = "https://downloads.apache.org/maven/mvnd/${version}/maven-mvnd-${version}-darwin-amd64.zip";
      hash = "sha256-yf+WBcOdOM3XsfiXJThVws2r84vG2jwfNV1c+sq6A4s=";
    };
    aarch64-darwin = {
      url = "https://downloads.apache.org/maven/mvnd/${version}/maven-mvnd-${version}-darwin-aarch64.zip";
      hash = "sha256-0Vecksvecqw10kXc0yMK2Hafxwk19dVYChi17ZDQP8M=";
    };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mvnd";
  inherit version;
  src = fetchzip {
    inherit (sources.${stdenvNoCC.system} or (throw "Unsupported system: ${stdenvNoCC.system}"))
      url
      hash
      ;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/nix-support
    cp -r $src/* $out/nix-support/

    makeWrapper $out/nix-support/bin/mvnd $out/bin/mvnd \
      --set-default JAVA_HOME "${jdk}" \
      --set-default MVND_HOME "$out/nix-support/mvnd"

    runHook postInstall
  '';

  meta = with lib; {
    mainProgram = "mvnd";
    description = "Build automation tool (used primarily for Java projects)";
    homepage = "https://maven.apache.org/";
    license = licenses.asl20;
    platforms = platforms.unix;
    # maintainers = with maintainers; [ cko ];
  };
})
