{
  # buildGraalvmNativeImage,
  jre,
  maven,
  writeShellApplication,
  ...
}:
let
  pname = "spring-javaformat";
  version = "0.0.44";
  jar = maven.buildMavenPackage {
    inherit pname version;
    src = ./.;

    # buildOffline = true;
    mvnHash = "sha256-Yz8tK3Vy6CBU4/nvyC1OSmgFDaFn+bl7KZYo5mJnP9Y=";

    installPhase = ''
      mv ./target/spring-format-cli-${version}.jar $out
    '';
  };
in
writeShellApplication {
  name = "spring-javaformat";
  runtimeInputs = [ jre ];
  text = ''
    java -jar ${jar} "$@"
  '';
}
# in
# buildGraalvmNativeImage {
#   inherit pname version;
#
#   src = jar;
#
#   executable = "spring-javaformat";
#
#   extraNativeImageBuildArgs = [
#     "-Ob"
#     # "-Os"
#     ''-H:IncludeResources=".*"''
#   ];
#
#   doInstallCheck = true;
#
#   installCheckPhase = ''
#     file=${jar.src}/src/main/java/io/spring/format/cli/SpringJavaFormat.java
#     echo $file | $out/bin/spring-javaformat $file
#   '';
# }
