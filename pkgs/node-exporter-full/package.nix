{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2025-05-08";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "df301c969c25033c127eabf193c3ff2e6fd46d76";
    sha256 = "sha256-gtrG39xY2+5jxuq3Lfm5MxtlxQzLZxyUgKvIz36W1+8=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
