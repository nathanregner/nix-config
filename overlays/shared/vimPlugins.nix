prev: vimPlugins:
let
  inherit (prev) lib;

  base = vimPlugins.nvim-treesitter;

  # Rebuild nvim-treesitter's `java` grammar from the java-orchard source.
  # Reuses the checked-in java grammar's language ("java") and bundled queries
  # so it drops in as a replacement; the grammar name is patched to "java" so
  # `tree-sitter generate` emits the `tree_sitter_java` symbol neovim loads.
  javaGrammar = base.passthru.builtGrammars.java.overrideAttrs (old: {
    inherit (prev.local.tree-sitter-java-orchard) version src;
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      prev.nodejs
      prev.tree-sitter
    ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace grammar.js --replace-fail "name: 'java_orchard'" "name: 'java'"
      substituteInPlace tree-sitter.json --replace-fail '"name": "java_orchard"' '"name": "java"'
    '';
    preBuild = "tree-sitter generate";
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      HOME=$(mktemp -d) tree-sitter test
      runHook postCheck
    '';
  });

  origWithPlugins = base.passthru.withPlugins;
  substitute = grammars: grammars // {
    java = javaGrammar;
    tree-sitter-java = javaGrammar;
  };

  nvim-treesitter = base.overrideAttrs (old: {
    passthru = old.passthru // {
      builtGrammars = substitute old.passthru.builtGrammars;
      grammarPlugins = old.passthru.grammarPlugins // {
        java = prev.neovimUtils.grammarToPlugin javaGrammar;
      };
      withPlugins = f: origWithPlugins (grammars: f (substitute grammars));
      withAllGrammars = origWithPlugins (
        _: map (g: if lib.getName g == "tree-sitter-java" then javaGrammar else g) old.passthru.allGrammars
      );
    };
  });
in
vimPlugins // { inherit nvim-treesitter; }
