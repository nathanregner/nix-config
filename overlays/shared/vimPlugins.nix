prev: vimPlugins:
let
  inherit (prev) lib;

  base = vimPlugins.nvim-treesitter;

  # Replace nvim-treesitter grammars with alternate sources, keyed by the
  # nvim-treesitter language name. Each entry rebuilds the checked-in grammar
  # from `package`'s source (reusing the language and bundled queries so it
  # drops in as a replacement) and patches the upstream grammar name to the
  # language name, so `tree-sitter generate` emits the `tree_sitter_<name>`
  # symbol neovim loads.
  overrides = {
    java = {
      package = prev.local.tree-sitter-java-orchard;
      grammar = "java_orchard";
    };
  };

  mkGrammar =
    name:
    { package, grammar }:
    base.passthru.builtGrammars.${name}.overrideAttrs (old: {
      inherit (package) version src;
      patches = (old.patches or [ ]) ++ (package.patches or [ ]);
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        prev.nodejs
        prev.tree-sitter
      ];
      postPatch = (old.postPatch or "") + ''
        substituteInPlace grammar.js --replace-fail "name: '${grammar}'" "name: '${name}'"
        substituteInPlace tree-sitter.json --replace-fail '"name": "${grammar}"' '"name": "${name}"'
      '';
      preBuild = "tree-sitter generate";
      doCheck = true;
      checkPhase = ''
        runHook preCheck
        HOME=$(mktemp -d) tree-sitter test
        runHook postCheck
      '';
    });

  grammars = lib.mapAttrs mkGrammar overrides;

  # Aliases mirror nvim-treesitter's builtGrammars (`tree-sitter-<name>`).
  substitute =
    set: set // grammars // lib.mapAttrs' (name: g: lib.nameValuePair "tree-sitter-${name}" g) grammars;

  # The stock java queries don't compile against the orchard grammar. `withPlugins`
  # rebuilds from the unoverridden plugin, so its result has to be patched as well.
  patchQueries =
    plugin:
    plugin.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./patches/0001-fix-java-adapt-highlights-to-tree-sitter-java-orchard.patch
      ];
    });

  origWithPlugins = base.passthru.withPlugins;

  nvim-treesitter = (patchQueries base).overrideAttrs (old: {
    passthru = old.passthru // {
      builtGrammars = substitute old.passthru.builtGrammars;
      grammarPlugins =
        old.passthru.grammarPlugins // lib.mapAttrs (_: prev.neovimUtils.grammarToPlugin) grammars;
      withPlugins = f: patchQueries (origWithPlugins (set: f (substitute set)));
      withAllGrammars = patchQueries (
        origWithPlugins (
          _:
          map (
            g: grammars.${lib.removePrefix "tree-sitter-" (lib.getName g)} or g
          ) old.passthru.allGrammars
        )
      );
    };
  });
in
vimPlugins // { inherit nvim-treesitter; }
