{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2026-10-16";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "b173daed1bb163ca320cc3624206e07832219113";
    sha256 = "sha256-hKzhMxZsagj4i0zHUbAxmx1k+J3ZDwwJW09AAlYgVsQ=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
