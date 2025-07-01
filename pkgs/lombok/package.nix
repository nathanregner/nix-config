{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch2,
  ant,
  jdk,
  stripJavaArchivesHook,
}:
stdenv.mkDerivation {
  pname = "lombok";
  version = "1.18.39";

  src = fetchFromGitHub {
    owner = "projectlombok";
    repo = "lombok";
    rev = "94b01e45ce28cc700eebab0523b5c566fff6e57e";
    hash = "sha256-DnLFYHv69DTIK3DYQ6oTic8Dh8KRwNAEh2BeD/RWpFo=";
  };

  patches = [
    (fetchpatch2 {
      url = "https://patch-diff.githubusercontent.com/raw/projectlombok/lombok/pull/3888.patch";
      hash = "sha256-Ri32bzScNdqzS6ksuBN2ZR/+Rne96KW73tfmqZDrqh0=";
    })
  ];

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-CPjfPlnR+93SlppMqgDrpJRXZO7Dy2a46Wbi3ayUkn4=";

  nativeBuildInputs = [
    ant
    (lib.throwIf ((jdk.passthru.cato or false) == false) "jdk is not wrapped" jdk)
    stripJavaArchivesHook # removes timestamp metadata from jar files
  ];

  buildPhase = ''
    runHook preBuild
    ant maven
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # copy generated jar file(s) to an appropriate location in $out
    install -Dm644 dist/lombok.jar $out

    runHook postInstall
  '';
}
