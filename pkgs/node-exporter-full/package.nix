{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2025-07-10";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "1fc4c730f8213fdb2aa4e71fa3d0021cb7d5d1f1";
    sha256 = "sha256-h7eW/Xv1mRGEBlOaRjqPwKwMK8xEe3KSk0rbFhNZwLg=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
