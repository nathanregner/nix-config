{
  lib,
  fetchFromGitHub,
  nix-update-script,
  stdenv,
}:
stdenv.mkDerivation rec {
  pname = "showevtinfo";
  version = "4.13.0";

  src = fetchFromGitHub {
    owner = "wcohen";
    repo = "libpfm4";
    rev = "v${version}";
    hash = "sha256-EylpPjCRcIH98naeg3Cya1jpJQ5NprsGOusGXi2YA1o=";
  };

  enableParallelBuilding = true;

  installPhase = ''
    mkdir -p $out/bin
    cp examples/showevtinfo $out/bin
    cp examples/check_events $out/bin
  '';

  passthru.updateScript = nix-update-script { };

  meta.platforms = lib.platforms.linux;
}
