{
  fetchurl,
  jdk,
  makeWrapper,
  nix-update-script,
  stdenvNoCC,
  unzip,
}:
let
  version = builtins.fromTOML (builtins.readFile ./version.toml);
in
stdenvNoCC.mkDerivation {
  pname = "kotlin-lsp";
  inherit (version) version;

  src = fetchurl {
    inherit (version) url hash;
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin

    cd $out
    unzip $src

    chmod +x kotlin-lsp.sh

    makeWrapper $out/kotlin-lsp.sh bin/kotlin-lsp \
      --prefix JAVA_HOME : "${jdk}"

    rm kotlin-lsp.cmd
  '';

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/Kotlin/kotlin-lsp";
  };
}
