{
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule ({
  pname = "joker";
  version = "1.4.0";
  src = fetchFromGitHub {
    owner = "candid82";
    repo = "joker";
    rev = "v1.4.0";
    fetchSubmodules = false;
    sha256 = "sha256-Y7FaW3V80mXp3l87srTLyhF45MlNH7QUZ5hrTudPtDU=";
  };

  vendorHash = "sha256-t/28kTJVgVoe7DgGzNgA1sYKoA6oNC46AeJSrW/JetU=";

  preBuild = ''
    go generate ./...
  '';

  passthru.updateScript = nix-update-script { };
})
