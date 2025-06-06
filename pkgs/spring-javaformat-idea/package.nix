{ srcOnly, fetchurl }:
srcOnly rec {
  name = "spring-javaformat-intellij-idea-plugin";
  version = "0.0.46";
  src = fetchurl {
    url = "https://repo1.maven.org/maven2/io/spring/javaformat/spring-javaformat-intellij-idea-plugin/${version}/spring-javaformat-intellij-idea-plugin-${version}.jar";
    hash = "sha256-E8OA03TAPuVoioXxuDHTkpnGexWeqDfBW1nBT+1PeCE=";
  };
}
