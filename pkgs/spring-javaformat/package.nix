{
  jre,
  lib,
  jdk,
  temurin-bin-24,
  jsvc,
  maven,
  writeShellApplication,
  ...
}:
let
  pname = "spring-javaformat";
  version = "0.0.45";
  jar = maven.buildMavenPackage {
    inherit pname version;
    src = ./.;

    # buildOffline = true;
    mvnHash = "sha256-uMGyztJtfY5EpmIOfdIW80p9h+wZhajWfXtzBeLaeGg=";
    mvnParameters = lib.escapeShellArgs [
      "-Daether.connector.https.securityMode=insecure"
    ];

    installPhase = ''
      mv ./target/spring-format-cli-${version}.jar $out
    '';
  };
in
writeShellApplication {
  name = "spring-javaformat";
  runtimeInputs = [
    (jsvc.overrideAttrs {
      # makeFlags = [ "-DJSVC_UMASK=022" ];
    })
  ];
  text = ''
    exec jsvc \
      -user "$USER" \
      -home "$HOME" \
      -server \
      -java-home ${jdk}/Library/Java/JavaVirtualMachines/zulu-21.jdk/Contents/Home \
      -pidfile ~/.cache/spring-javaformat.pid \
      -wait 90 \
      -cp ${jar} \
      -outfile "$(pwd)/out.txt" \
      -errfile "$(pwd)/err.txt" \
      -debug -verbose \
      io.spring.format.cli.SimpleDaemon
  '';
  passthru = { inherit jar; };
}
