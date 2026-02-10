{
  fetchFromGitHub,
  stdenv,
  tree-sitter,
  writers,
}:
let
  inherit (builtins.fromJSON (builtins.readFile ./version.lock))
    src
    grammar
    ;

  drv = stdenv.mkDerivation (finalAttrs: {
    pname = "topiary-nushell";
    version = "latest";
    src = fetchFromGitHub src;

    installPhase = ''
      cp $src/queries/nu.scm $out
    '';

    passthru = {
      updateScript = [
        (writers.writeNu "update-topiary-nushell" ''
          let position = echo '${drv.meta.position}' | parse --regex '/nix/store/\w+-source/(?<path>.*):\d+' | first
          ${./update.nu} ([($position.path | path dirname) version.lock] | path join)
        '')
      ];

      grammar = tree-sitter.passthru.buildGrammar {
        language = "nu";
        version = grammar.src.rev;
        src = fetchFromGitHub grammar.src;
      };
    };
  });
in
drv
