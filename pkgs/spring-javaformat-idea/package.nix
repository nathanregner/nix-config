{ fetchurl }:
let
  version = "0.0.45";
in
fetchurl {
  url = "https://repo1.maven.org/maven2/io/spring/javaformat/spring-javaformat-intellij-idea-plugin/${version}/spring-javaformat-intellij-idea-plugin-${version}.jar";
  hash = "sha256-Ao88DXM7oyKfchh1ZY/nEs7jRF5/+po4DRMS1rmG+G8=";
}
