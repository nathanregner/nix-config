{ tree-sitter }:
tree-sitter.buildGrammar {
  language = "selfie_snapshot";
  version = "0.1.0";
  src = ./.;
  generate = true;

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    HOME=$(mktemp -d) tree-sitter test
    runHook postCheck
  '';
}
