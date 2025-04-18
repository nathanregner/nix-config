{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2025-04-13";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "c612c5e85e6f30d39969cecf21ce339ea242a243";
    sha256 = "sha256-GcGBAbe3dB7yUwP/uH36ZmF2pv4hcUtFobeG3/yvtQ0=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
