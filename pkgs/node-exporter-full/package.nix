{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2025-01-18";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "33a41b565033d61af48b8138824965d43d4e2fc4";
    sha256 = "sha256-ZkVijMRCd87sLckqezPh1wHfuiibExVhatA1AqRiKHc=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
