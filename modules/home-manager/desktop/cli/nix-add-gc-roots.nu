#!/usr/bin/env -S nu --stdin

def main [
  dir: string
  --remove
] {
  let gcroots = $"($env.HOME)/.cache/nix/gcroots/($dir)"
  let linked =  $in | split row --regex \s+ | filter {|it| $it | is-not-empty } | par-each {|src|
    let dest = $gcroots | path join ($src | path basename)
    print $"($src) -> ($dest)"
    nix build $src --out-link $dest
    {$dest: $src}
  } | reduce {|it| merge $it }

  mut result = {linked: $linked}
  if $remove {
    let removed = ls $gcroots | group-by name | reject ...($linked | columns) | columns | each {|path|
      rm $path
      $path
    }
    $result = $result | merge {removed: $removed}
  }
  $result
}
