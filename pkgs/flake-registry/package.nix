{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "flake-registry";
  version = "0-unstable-2025-04-14";
  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "flake-registry";
    rev = "1322f33d5836ae757d2e6190239252cf8402acf6";
    fetchSubmodules = false;
    sha256 = "sha256-nlQTQrHqM+ywXN0evDXnYEV6z6WWZB5BFQ2TkXsduKw=";
  };
  installPhase = ''
    mv flake-registry.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
