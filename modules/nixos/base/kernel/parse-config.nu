#!/usr/bin/env nu
def main [path: string] {
  open $path
  | lines
  | where {|line| $line =~ "^CONFIG_" }
  | reduce --fold {} {|line, acc|
    let opt = $line | split row "="
    let key = $opt.0
    mut value = $opt.1
    # unquote strings
    try { $value = $value | from json }
    $acc | insert $key $value
  }
  | sort
  | to json
}
