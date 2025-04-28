#!/usr/bin/env nu
use std/log

def last_fetch [dir: string] {
  let fetch_head = glob ($dir | path join "{.git,.bare}/FETCH_HEAD")
  if ($fetch_head | is-not-empty) {
    stat -c %y ($fetch_head | first) | into datetime
  }
}

def is_git [dir: string] {
  glob ($dir | path join "{.git,.bare}/objects") | is-not-empty
}

def maybe_fetch [older_than: duration] {
  let last_fetch = last_fetch $env.PWD
  let fetch_threshold = (date now) - $older_than

  if $last_fetch == null or $last_fetch < $fetch_threshold {
    log info $"Fetching ($env.PWD) \(last fetch ($last_fetch))"
    git fetch origin main
  }
}

def list_worktrees [] {
  git worktree prune
  git worktree list --porcelain
  | split row "\n\n"
  | each {|block| $block | parse --regex "(?m)^worktree\\s+(?<path>.*)$\n.*\n^branch\\s+refs/heads/(?<branch>.*)$" }
  | flatten
}

def find_or_create_worktree [$branch: string] {
  let worktrees = list_worktrees | where branch == $branch
  if ($worktrees | is-not-empty) {
    ($worktrees | first).path
  } else {
    let path = (mktemp -d)
    git worktree add -b $branch $path
    $path
  }
}

def --wrapped main [
  --branch: string = for-each-repo
  --root: string = ~/dev/engineering
  --threads: number = 8
  --pattern: string = .
  --fetch: duration
  --reset
  cmd?: string
  ...rest: string
] {
  log info $pattern
  log info $"$(fd --type directory --maxdepth=1 $pattern ($root | path expand) | lines | filter {|dir| is_git $dir })"
  fd --type directory --maxdepth=1 $pattern ($root | path expand)
  | lines
  | filter {|dir| is_git $dir }
  | par-each --threads $threads {|dir|
    try {
      cd $dir
      if $fetch != null {
        maybe_fetch $fetch
      }
      let worktree = (find_or_create_worktree $branch)
      cd $worktree
      if $reset {
        log info $"reset ($env.pwd)"
        git reset --hard origin/main
      }
      if $cmd != null {
        log info $"($cmd)"
        (exec $cmd ...$rest)
      }
      $worktree
    } catch {|error|
      log error $"Failed to update repo ($dir): ($error)"
    }
  }
}
