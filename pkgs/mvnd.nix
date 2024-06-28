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
  targets = {
    "aarch64-darwin" = "darwin-aarch64";
    "aarch64-linux" = "linux-aarch64";
    "x86_64-darwin" = "darwin-amd64";
    "x86_64-linux" = "linux-amd64";
  };
in

maven.buildMavenPackage (
  source
  // {
    nativeBuildInputs = [
      graalvmCEPackages.graalvm-ce
      makeWrapper
    ] ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Foundation ];

    # build in the deps phase... deps plugin doesn't download everything it needs for offline mode
    # https://issues.apache.org/jira/browse/MDEP-82
    # https://github.com/NixOS/nixpkgs/issues/135907
    mvnDepsParameters = "-s ${./mvnd/settings.xml} -Daether.dependencyCollector.impl=bf -Dmaven.artifact.threads=32";
    mvnHash = "sha256-PjjPuAXSyNG7OHZrxDKawFFqSW+jbvUMu6kXXdvPzEg=";

    buildOffline = true;

    # some plugins not fetched
    # https://github.com/qaware/go-offline-maven-plugin/issues/23
    manualMvnArtifacts = [
      "org.apache.apache.resources:apache-jar-resource-bundle:1.5"
      "org.apache.maven:apache-maven:3.9.8:tar.gz:bin"
      "org.apache.maven:maven-slf4j-provider:3.9.8:jar:sources"
      "org.graalvm.buildtools:graalvm-reachability-metadata:0.10.2:zip:repository"
      "org.graalvm.buildtools:native-maven-plugin:0.10.2"
    ];

    mvnParameters = lib.concatStringsSep " " [
      # skip tests; they require network acccess
      "-DskipTests=true"
      "-pl"
      "!integration-tests"

      "-Dmaven.buildNumber.skip=true" # skip build number generation; requires git and we're building a tag
      "-Drat.skip=true" # skip license checks; they require manaul approval and should have already been run upstream
      "-Dspotless.skip=true" # skip formatting checks

      "-Pnative"
      # Propagate linker args required by the darwin build
      # > Pass the whole environment to the native-image build process by
      # > generating a -E option for every environment variable.
      # source: `buildGraalvmNativeImage`
      ''-Dgraalvm-native-static-opt="-H:-CheckToolchain $(export -p | sed -n 's/^declare -x \([^=]\+\)=.*$/ -E\1/p' | tr -d \\n)"''
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/mvnd-home

      cp -r dist/target/maven-mvnd-1.0.1-${targets.${stdenv.system}}/* $out/mvnd-home
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
