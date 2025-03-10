{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "klipper-adaptive-meshing-purging";
  version = "1.1.2";
  src = fetchFromGitHub {
    owner = "kyleisah";
    repo = "Klipper-Adaptive-Meshing-Purging";
    rev = "v${version}";
    fetchSubmodules = false;
    sha256 = "sha256-anBGjLtYlyrxeNVy1TEMcAGTVUFrGClLuoJZuo3xlDM=";
  };

  installPhase = ''
    mv Configuration $out
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A unique leveling solution for Klipper-enabled 3D printers!";
    homepage = "https://github.com/kyleisah/Klipper-Adaptive-Meshing-Purging";
  };
}
