{
  installShellFiles,
  sources,
  stdenv,
}:
let
  throwSystem = throw "Unsupported system: ${stdenv.hostPlatform.system}";
  arch =
    {
      x86_64-darwin = "amd64";
      aarch64-darwin = "arm64";
    }
    .${stdenv.hostPlatform.system} or throwSystem;
in
stdenv.mkDerivation (
  sources.authbind
  // {
    nativeBuildInputs = [
      installShellFiles
    ];

    preBuild = ''
      makeFlagsArray+=(
        ARCH="-arch ${arch}"
        prefix=$out
        lib_dir=$out/lib
      )
    '';

    installTargets = "";
    installPhase = ''
      runHook preInstall

      installBin authbind authbind
      install -D libauthbind.dylib $out/lib/libauthbind.dylib
      installManPage authbind.1

      runHook postInstall
    '';
  }
)
