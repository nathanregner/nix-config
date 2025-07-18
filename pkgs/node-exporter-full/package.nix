{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2025-07-23";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "925c74c8af03133a5c1969a73b5af8ef4fe1c488";
    sha256 = "sha256-SiYaSNgXGFyEJaL0xbD8rXBcetl3P5ylA0CwOD4cJbU=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
