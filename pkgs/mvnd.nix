{
  source,
  lib,
  graalvmCEPackages,
  maven,
  stdenv,
  darwin,
}:

let
  stdenv' = graalvmCEPackages.stdenv;
in
(maven.buildMavenPackage.override { stdenv = stdenv'; }) (
  source
  // rec {

    nativeBuildInputs =
      [ graalvmCEPackages.graalvm-ce ]
      ++ lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.Foundation
        darwin.apple_sdk_11_0.stdenv.cc
      ];

    # postgis config directory assumes /include /lib from the same root for json-c library
    # env.NIX_LDFLAGS = "-L${lib.getLib json_c}/lib";
    # NIX_DEBUG = 7;

    extraBuildInputs = lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Foundation ];

    propagatedBuildInputs = lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Foundation ];

    # patches = [ ./mvnd/mvnd.patch ];

    # build in the deps phase... deps plugin doesn't download everything it needs for offline mode
    # https://github.com/qaware/go-offline-maven-plugin/issues/23
    # https://issues.apache.org/jira/browse/MDEP-82
    # https://github.com/NixOS/nixpkgs/issues/135907
    mvnDepsParameters = "-s ${./mvnd/settings.xml} -Daether.dependencyCollector.impl=bf -Dmaven.artifact.threads=32";
    mvnHash = "sha256-12+Rzlurut4QyK7b8AzLRo6AJY4kcdmseJ7g4anm70k=";

    buildOffline = true;

    manualMvnArtifacts = [
      "org.apache.apache.resources:apache-jar-resource-bundle:1.5"
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
      # ''-Dorg.graalvm.buildtools.buildArgs="-H:-CheckToolchain $(export -p | sed -n 's/^declare -x \([^=]\+\)=.*$/ -E\1/p' | tr -d \\n)"''
    ];

    installPhase = ''
      mkdir -p $out/mvnd
      mkdir -p $out/bin
      cp -r client/target $out

      runHook postInstall
    '';

    passthru.framework = darwin.apple_sdk.frameworks.Foundation;
    passthru.core = darwin.apple_sdk.frameworks.CoreFoundation;
  }
)
