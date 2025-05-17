{
  fetchFromGitHub,
  nix-update-script,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "node-exporter-full.json";
  version = "0-unstable-2025-05-16";
  src = fetchFromGitHub {
    owner = "rfmoz";
    repo = "grafana-dashboards";
    rev = "4e24da4d94e33bf521f43f4d76d428665050bf03";
    sha256 = "sha256-7gbFBjbnapt1SHgksAASxt0UplHZ9CI3TBXgz5Wq8+s=";
  };

  installPhase = ''
    mv prometheus/node-exporter-full.json $out
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
