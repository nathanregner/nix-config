{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "sf-mono-nerd-font";
  version = "18.0d1e1.0";
  src = fetchFromGitHub {
    owner = "epk";
    repo = "SF-Mono-Nerd-Font";
    rev = "v${version}";
    fetchSubmodules = false;
    sha256 = "sha256-f5A/vTKCUxdMhCqv0/ikF46tRrx5yZfIkvfExb3/XEQ=";
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
