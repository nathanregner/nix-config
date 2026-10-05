{
  lib,
  stdenv,
  fetchurl,
  jdk,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "log4jdbc-agent";
  version = "1.16";

  src = fetchurl {
    url = "https://repo1.maven.org/maven2/org/bgee/log4jdbc-log4j2/log4jdbc-log4j2-jdbc4.1/${finalAttrs.version}/log4jdbc-log4j2-jdbc4.1-${finalAttrs.version}.jar";
    hash = "sha256-tiPPxWwET7E5NNUwV6xM5asZn0osesQX2n7gKFPkGoI=";
  };

  nativeBuildInputs = [ jdk ];

  buildCommand = ''
    mkdir classes
    (cd classes && jar xf $src && rm META-INF/MANIFEST.MF)

    javac --release 8 -nowarn -d classes ${./src}/log4jdbc/agent/Log4jdbcAgent.java
    # bundled so log4jdbc logs via slf4j (spring boot's logback) instead of log4j2
    cp ${./src}/log4jdbc.log4j2.properties classes/

    printf 'Premain-Class: log4jdbc.agent.Log4jdbcAgent\n' > manifest.txt
    mkdir -p $out/share/java
    jar cfm $out/share/java/log4jdbc-agent.jar manifest.txt -C classes .
  '';

  meta = {
    description = "log4jdbc-log4j2 repackaged as a -javaagent so it can be added to any JVM's class path";
    homepage = "https://github.com/bgeeproject/log4jdbc-log4j2";
    platforms = lib.platforms.all;
    license = lib.licenses.asl20;
  };
})
