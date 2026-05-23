{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "sf-mono-nerd-font";
  version = "15.0d5e1";
  src = fetchFromGitHub {
    owner = "epk";
    repo = "SF-Mono-Nerd-Font";
    rev = "v${version}";
    fetchSubmodules = false;
    sha256 = "sha256-IkTbd5qpWue9utkCVHTvPSHnrVLBU3OQ9BqorNU7yQk=";
  };

  dontBuild = true;
  dontFixup = true;
  dontStrip = true;
  installPhase = ''
    mkdir -p $out/share/fonts/${pname}
    cp ${src}/*.otf $out/share/fonts/${pname}
  '';

  passthru.updateScript = nix-update-script { };
}
