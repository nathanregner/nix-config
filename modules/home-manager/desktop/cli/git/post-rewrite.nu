#!/usr/bin/env nu

use std/log

const file = ".git-blame-ignore-revs"

def main [cause: string] {
  if not ($file | path exists) {
    return
  }

  let input = $in
  if ($input | is-empty) {
    return
  }

  let mapping = (
    $input
    | lines
    | each {|line| $line | split row ' ' | { old: $in.0, new: $in.1 } }
  )

  let lines = (open $file | lines)
  let updated = ($lines | each {|line|
    if ($line | str trim | is-empty) or ($line | str starts-with "#") {
      $line
    } else {
      let match = ($mapping | where old == $line | first -s)
      if ($match | is-not-empty) {
        log info $"Updating ($line) -> ($match.new)"
        $match.new
      } else {
        $line
      }
    }
  })

  if $updated != $lines {
    $updated | str join "\n" | save -f $file
  }
}
