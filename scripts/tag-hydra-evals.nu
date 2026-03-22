#!/usr/bin/env nu

use std log

def parse-eval [] {
  {
    id: $in.id
    timestamp: ($in.timestamp | into datetime -f '%s' | date to-timezone "America/Boise" | format date "%+")
    commit: ($in.flake | parse --regex "github:[^/]+?/[^/]+?/(?<commit>[^/]+)?\\?" | first | get -o commit)
  }
}

def tag-eval [] {
  with-env {GIT_COMMITTER_DATE: $in.timestamp} {
    let tag = $"eval-($in.id)"
    git tag -a $tag -m "" -f $in.commit
    $tag
  }
}

let tags = (
  http get https://hydra.nregner.net/jobset/nix-config/master/evals
  --headers {'Content-Type': 'application/json'}
)
  | get evals
  | each {
    let eval = $in | parse-eval
    try {
      $eval | tag-eval
    } catch {
      log error $"Failed to tag ($eval)"
    }
  }

git push origin tag ...$tags
