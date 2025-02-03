{
  # buildGraalvmNativeImage,
  # graalvmPackages,
  jre,
  maven,
  writeShellApplication,
  ...
}:
let
  pname = "spring-javaformat";
  version = "0.0.43";
  jar = maven.buildMavenPackage {
    inherit pname version;
    src = ./.;

    buildOffline = true;
    mvnHash = "sha256-wmzAcU4LuGswFEv616KMFLn8Z1gHJrgRIy1KhOCkjes=";

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
#   graalvmDrv = graalvmPackages.graalvm-ce;
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
