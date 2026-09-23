{
  tree-sitter,
  fetchFromGitea,
  nix-update-script,
}:
tree-sitter.buildGrammar {
  language = "java_orchard";
  version = "0.5.18";
  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "grammar-orchard";
    repo = "tree-sitter-java-orchard";
    rev = "81b7484a2e249428a7b7b90c0027ac53ac6d22c8";
    hash = "sha256-lvyZ8y+6OxtydOsyl8TVoHi2wzOlzwLjWZoP4rreBRo=";
  };
  generate = true;

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    HOME=$(mktemp -d) tree-sitter test
    runHook postCheck
  '';

  passthru.updateScript = nix-update-script { };
}
