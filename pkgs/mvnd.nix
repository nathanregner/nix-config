{
  source,
  lib,
  darwin,
  graalvmCEPackages,
  jdk,
  maven,
  stdenv,
}:

assert jdk != null;

maven.buildMavenPackage (
  source
  // rec {

    nativeBuildInputs = [
      graalvmCEPackages.graalvm-ce
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
      "-DskipTests=true"
      "-Dmaven.buildNumber.skip=true"
      "-Drat.skip=true"
      "-Denforcer.skip=true"
      "-Dspotless.skip=true"
      ''-Dgraalvm-native-static-opt="-H:-CheckToolchain $(export -p | sed -n 's/^declare -x \([^=]\+\)=.*$/ -E\1/p' | tr -d \\n)"''
      "-pl"
      "!integration-tests"
    ];

    installPhase = ''
      mkdir -p $out/mvnd
      mkdir -p $out/bin
      cp -r client/target $out

      makeWrapper $out/mvnd/bin/mvnd $out/bin/mvnd \
        --set-default JAVA_HOME "${jdk}"

      runHook postInstall
    '';
  }
)
