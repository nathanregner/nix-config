#!/usr/bin/env nu

use std/log

const file = ".git-blame-ignore-revs"

def prune [lines: list<string>] {
  $lines | where {|hash|
    if ($hash | str trim | is-empty) or ($hash | str starts-with "#") {
      true
    } else {
      let result = (do { git merge-base --is-ancestor $hash HEAD } | complete)
      if $result.exit_code != 0 {
        log warning $"Removing ($hash) - not in current branch"
      }
      $result.exit_code == 0
    }
  }
}

def select-commit [] {
  git log --oneline --color=always
  | fzf --ansi --no-sort --preview 'git show --color=always {1}'
  | split row ' '
  | first
}

def add [lines: list<string> rev: string] {
  let hash = (git rev-parse $rev | str trim)

  if $hash in $lines {
    log info $"($hash) already in ($file)"
    return $lines
  }

  log info $"Added ($hash) to ($file)"
  $lines | append $hash
}

def main [rev?: string] {
  mut lines = if ($file | path exists) { open $file | lines } else { [] }
  $lines = (prune $lines)

  let commit = if ($rev | is-empty) { select-commit } else { $rev }
  if not ($commit | is-empty) {
    $lines = (add $lines $commit)
  }

  $lines | str join "\n" | save -f $file
}
