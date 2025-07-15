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
  --single_root
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

  if $single_root {
    print {
      inputDrvs: {
        "/nix/store/6lkh5yi7nlb7l6dr8fljlli5zfd9hq58-curl-7.73.0.drv": ["dev"]
        "/nix/store/fn3kgnfzl5dzym26j8g907gq3kbm8bfh-unzip-6.0.drv": ["out"]
      }
    }
  }

  # $result
  return
}
