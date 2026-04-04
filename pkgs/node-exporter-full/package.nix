{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2026-03-31";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "73ab1c60fff2f3be454a2955b6a5502ae7a2abca";
    sha256 = "sha256-J0cp54oGSudoZUgF0vCaCbwulEzHmSOdxN62vlydbXY=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
