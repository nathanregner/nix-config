{
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  name = "spring-javaformat-intellij-idea-plugin";
  version = "0.0.47";
  src = fetchurl {
    url = "https://repo1.maven.org/maven2/io/spring/javaformat/spring-javaformat-intellij-idea-plugin/${version}/spring-javaformat-intellij-idea-plugin-${version}.jar";
    hash = "sha256-fysHZw/ROIzqymZx6/b2q5/x+d84lDyfb5gSP4bUGUc=";
  };
  dontUnpack = true;

  installPhase = ''
    cp $src $out
  '';
}
