#!/usr/bin/env nix-shell
#!nix-shell -i nu -p nix-prefetch-github nickel

def fetch_src [] {
  nix-prefetch-github blindFS topiary-nushell | from json
}

def fetch_grammar [rev] {
  nix-prefetch-github nushell tree-sitter-nu --rev $rev | from json
}

def main [out] {
  let src = fetch_src
  let grammar_src = http get $"https://raw.githubusercontent.com/blindFS/topiary-nushell/($src.rev)/languages.ncl"
  | nickel export
  | from json
  | get languages.nu.grammar.source.git.rev
  | fetch_grammar $in

  {
    src: $src
    grammar: {
      src: $grammar_src
    }
  }
  | to json
  | save -f $out
}
