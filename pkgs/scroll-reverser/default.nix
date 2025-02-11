{
  fetchurl,
  nix-update-script,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "scroll-reverser";
  version = "1.9";
  src = fetchurl {
    url = "https://github.com/pilotmoon/Scroll-Reverser/releases/download/v${version}/ScrollReverser-${version}.zip";
    sha256 = "sha256-CWHbtvjvTl7dQyvw3W583UIZ2LrIs7qj9XavmkK79YU=";
  };

  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  sourceRoot = "Scroll Reverser.app";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications/${sourceRoot}"
    cp -R . "$out/Applications/${sourceRoot}"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };
}
