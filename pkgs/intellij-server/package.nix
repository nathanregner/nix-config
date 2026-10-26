{
  lib,
  alsa-lib,
  autoPatchelfHook,
  fetchzip,
  fontconfig,
  freetype,
  libx11,
  libxi,
  libxrender,
  libxtst,
  makeWrapper,
  nix-update-script,
  stdenv,
  zlib,
}:
let
  version = "263.7084.0";
  base = "https://download.jetbrains.com/language-server/intellij-server/${version}/intellij-server-${version}";
  sources = {
    aarch64-darwin = {
      url = "${base}-aarch64.sit";
      hash = "sha256-KhTo9TKE2hsO4OYhlcQWWVSowFvUqeiZLAgz8HKGTVc=";
    };
    x86_64-darwin = {
      url = "${base}.sit";
      hash = "sha256-NLIVW4vu+T91fYi++1fVC82ZsFK41MtQQadPfHjZpVQ=";
    };
    aarch64-linux = {
      url = "${base}-aarch64.tar.gz";
      hash = "sha256-L0IKYE6MHvupEJjk/8dZV71EIj8TegtDP0zmFU4fYH8=";
    };
    x86_64-linux = {
      url = "${base}.tar.gz";
      hash = "sha256-PwxpoqkPQgaNuSlSebXxY/8XddYU3/baoq7dGRN4KF4=";
    };
  };
in
stdenv.mkDerivation {
  pname = "intellij-server";
  inherit version;

  src = fetchzip (
    sources.${stdenv.hostPlatform.system}
    // {
      # the .sit archives are plain zips, which fetchzip only unpacks by extension
      extension = if stdenv.hostPlatform.isDarwin then "zip" else null;
    }
  );

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    zlib
    freetype
    fontconfig
    alsa-lib
    libxtst
    libxrender
    libxi
    libx11
  ];

  # Re-signing/stripping would invalidate the bundled JetBrains Runtime
  dontStrip = true;
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/intellij-server $out/bin
    cp -r . $out/share/intellij-server
    # the launcher locates the bundled runtime relative to itself
    # the server refuses to start until it is given the leading 16 hex chars of the bundled EULA's sha256
    eulaHash=$(sha256sum $out/share/intellij-server/EULA.txt | cut -c1-16)
    makeWrapper $out/share/intellij-server/bin/intellij-server $out/bin/intellij-server \
      --add-flags "--eula=$eulaHash"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Java and Kotlin language server from IntelliJ IDEA";
    homepage = "https://www.jetbrains.com/help/intellij-vscode/About-instance.html";
    license = lib.licenses.unfree;
    mainProgram = "intellij-server";
    platforms = builtins.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
  };
}
