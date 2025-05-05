{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2025-05-02";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "cfa22383ef038b8b2bf00221afe7217acbecc76e";
    sha256 = "sha256-uwNmf5sfaV0Ok+eadEHiJZjTW6i8brIIo8B8eqZmXEg=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
