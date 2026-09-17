{
  lib,
  fetchFromGitHub,
  maven,
  nix-update-script,
}:
let
  version = "2.22.0-patched-SNAPSHOT";
  upstreamVersion = "2.22.0";
in
maven.buildMavenPackage {
  pname = "versions-maven-plugin";
  inherit version;

  src = fetchFromGitHub {
    owner = "mojohaus";
    repo = "versions";
    tag = upstreamVersion;
    hash = "sha256-fTuM2mB6tvyL448pHudmqCNECDUaW8G2n6BI7mSt/UM=";
  };

  # Only the null-version fix (UseLatestVersionsMojoBase); version bump via versions:set below.
  patches = [ ./null-version-fix.patch ];

  doCheck = false;
  mvnGoal = "install";
  mvnParameters = lib.concatStringsSep " " [
    "-Dmaven.test.skip=true"
    "-Dspotless.check.skip=true"
    "-Denforcer.skip=true"
    "-Danimal.sniffer.skip=true"
    "-Dcheckstyle.skip=true"
    "-Dmaven.javadoc.skip=true"
  ];

  # The njord extension calls System.getProperty("user.home") (not $HOME) to
  # locate its basedir. The sandbox user.home (/private/var/empty) is not
  # writable; override it via MAVEN_OPTS so the JVM picks it up at startup.
  preBuild = ''
    export HOME="$(mktemp -d)"
    export MAVEN_OPTS="$MAVEN_OPTS -Duser.home=$HOME"
  '';

  mvnFetchExtraArgs = {
    preBuild = ''
      export HOME="$(mktemp -d)"
      export MAVEN_OPTS="$MAVEN_OPTS -Duser.home=$HOME"
    '';

    # After `mvn package` finishes in the FOD (cert trust store configured,
    # $MAVEN_EXTRA_ARGS set), fetch artifacts needed by the offline main build
    # that `mvn package` didn't pull: the install plugin and versions plugin.
    postBuild = ''
      for artifact in \
        "org.apache.maven.plugins:maven-install-plugin:3.1.4" \
        "org.codehaus.mojo:versions-maven-plugin:${upstreamVersion}"; do
        mvn $MAVEN_EXTRA_ARGS dependency:get \
          -Dartifact="$artifact" \
          -Dmaven.repo.local=$out/.m2
      done
    '';
  };

  # Rewrite the reactor version before `mvn install` runs.
  afterDepsSetup = ''
    mvn -B -o -nsu org.codehaus.mojo:versions-maven-plugin:${upstreamVersion}:set \
      -DnewVersion=${version} \
      -DgenerateBackupPoms=false \
      -DprocessAllModules=true \
      -Dmaven.repo.local=$mvnDeps/.m2
  '';

  mvnHash = "sha256-Lj19ascTAWqBXeJU2jaqwR608T+0zJs6wTHRrw90Fmo=";

  # Maven install laid out all reactor artifacts at the correct groupId/artifactId
  # paths in $mvnDeps/.m2. Grab only the directories for our version.
  installPhase = ''
    runHook preInstall
    find "$mvnDeps/.m2" -type d -name "${version}" | while read -r dir; do
      rel="''${dir#$mvnDeps/.m2/}"
      mkdir -p "$out/repository/$(dirname "$rel")"
      cp -r "$dir" "$out/repository/$(dirname "$rel")/"
    done
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "versions-maven-plugin ${version} with a local fix for the null-version (BOM-managed dependency) NPE in use-latest-releases/use-latest-versions";
    homepage = "https://github.com/mojohaus/versions";
    license = lib.licenses.asl20;
  };
}
