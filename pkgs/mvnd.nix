{
  source,
  lib,
  darwin,
  graalvmCEPackages,
  jdk,
  maven,
  makeWrapper,
  stdenv,
}:

assert jdk != null;

let
  systemDist = {
    "aarch64-darwin" = "darwin-aarch64";
    "aarch64-linux" = "linux-aarch64";
    "x86_64-darwin" = "darwin-x86_64";
    "x86_64-linux" = "linux-x86_64";
  };
in

maven.buildMavenPackage (
  source
  // {

    nativeBuildInputs = [
      graalvmCEPackages.graalvm-ce
      makeWrapper
    ] ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Foundation ];

    # postgis config directory assumes /include /lib from the same root for json-c library
    # env.NIX_LDFLAGS = "-L${lib.getLib json_c}/lib";
    # NIX_DEBUG = 7;

    # build in the deps phase... deps plugin doesn't download everything it needs for offline mode
    # https://github.com/qaware/go-offline-maven-plugin/issues/23
    # https://issues.apache.org/jira/browse/MDEP-82
    # https://github.com/NixOS/nixpkgs/issues/135907
    mvnDepsParameters = "-s ${./mvnd/settings.xml} -Daether.dependencyCollector.impl=bf -Dmaven.artifact.threads=32";
    mvnHash = "sha256-PjjPuAXSyNG7OHZrxDKawFFqSW+jbvUMu6kXXdvPzEg=";

    buildOffline = true;

    manualMvnArtifacts = [
      "org.apache.apache.resources:apache-jar-resource-bundle:1.5"
      "org.apache.maven:apache-maven:3.9.8:tar.gz:bin"
      "org.apache.maven:maven-slf4j-provider:3.9.8:jar:sources"
      "org.graalvm.buildtools:graalvm-reachability-metadata:0.10.2:zip:repository"
      "org.graalvm.buildtools:native-maven-plugin:0.10.2"
    ];

    mvnParameters = lib.concatStringsSep " " [
      "-B"
      "-Pnative"
      # skip these goals so we don't need to include more manual artifacts
      "-DskipTests=true"
      "-Dmaven.buildNumber.skip=true"
      "-Drat.skip=true"
      # "-Denforcer.skip=true"
      "-Dspotless.skip=true"
      # Stolen from `buildGraalvmNativeImage`:
      # > Pass the whole environment to the native-image build process by
      # > generating a -E option for every environment variable.
      # Required to passthrough linker args for the darwin build
      ''-Dgraalvm-native-static-opt="-H:-CheckToolchain $(export -p | sed -n 's/^declare -x \([^=]\+\)=.*$/ -E\1/p' | tr -d \\n)"''
      "-pl"
      "!integration-tests"
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/mvnd-home

      cp -r dist/target/maven-mvnd-1.0.1-${systemDist.${stdenv.system}}/* $out/mvnd-home
      makeWrapper $out/mvnd-home/bin/mvnd $out/bin/mvnd \
        --set-default JAVA_HOME "${jdk}" \
        --set-default MVND_HOME $out/mvnd-home

      runHook postInstall
    '';

    meta = with lib; {
      mainProgram = "mvnd";
      description = "The Apache Maven Daemon";
      homepage = "https://maven.apache.org/";
      license = licenses.asl20;
      platforms = platforms.unix;
      # TODO
      # maintainers = with maintainers; [ cko ];
    };
  }
)
