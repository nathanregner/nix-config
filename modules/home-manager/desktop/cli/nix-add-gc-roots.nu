#!/usr/bin/env -S nu --stdin

def link [
  gcroots: string
  deref: bool
  paths: list<string>
] {
  $paths | par-each {|src|
    let src = if $deref { realpath $src } else { $src }
    let dest = $gcroots | path join ($src | path basename)
    print $"($src) -> ($dest)"
    nix build $src --out-link $dest
    {$dest: $src}
  } | reduce {|it| merge $it }
}

def remove [
  gcroots: string
  linked: list<string>
] {
  ls $gcroots
  | group-by name
  | reject ...$linked
  | columns
  | each {|path|
    rm $path
    $path
  }
}

def main [
  --prefix: string = "auto"
  --remove
  --deref
  ...paths: string
] {
  let paths = if ($paths | is-empty) { $in | lines } else { $paths }
  let gcroots = $"($env.HOME)/.cache/nix/gcroots/($prefix)"

  let linked = link $gcroots $deref $paths
  mut result = {linked: $linked}
  if $remove {
    let removed = remove $gcroots ($linked | columns)
    $result = $result | merge {removed: $removed}
  }
  $result
}
