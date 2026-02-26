#!/usr/bin/env nu

def parse-porcelain [] {
  str trim
  | split row --regex '\n\n'
  | each {|row|
    $row
    | lines
    | each {|line| split row --number 2 " " }
    | reduce --fold {} {|entry acc| $acc | insert $entry.0 $entry.1 }
  }
}

def get-current-worktree [] {
  git rev-parse --show-toplevel | complete | get stdout | str trim
}

def get-worktrees [] {
  git worktree list --porcelain
  | parse-porcelain
  | each {|it|
    {
      branch: ($it.branch | str replace 'refs/heads/' '')
      path: $it.worktree
    }
  }
}

def list-other-worktrees [] {
  let current = get-current-worktree

  get-worktrees
  | where path != $current
  | get branch
}

# List available worktrees (excluding current)
def "main list" [] {
  # Check if in a git repo
  if (git rev-parse --git-dir | complete | get exit_code) != 0 {
    exit 1
  }

  list-other-worktrees
}

# Switch to a worktree interactively or by name
def main [
  branch?: string  # Branch name to switch to (optional, uses fzf if not provided)
] {
  # Check if in a git repo
  if (git rev-parse --git-dir | complete | get exit_code) != 0 {
    error make {msg: "Error: not in a git repository"}
  }

  let current = get-current-worktree
  let worktrees = get-worktrees | where path != $current

  if ($worktrees | is-empty) {
    error make {msg: "Error: no other worktrees found"}
  }

  let selected = if ($branch == null) {
    # Interactive mode with fzf
    let choice = ($worktrees | get branch | to text | fzf)
    if ($choice | is-empty) {
      exit 1
    }
    $worktrees | where branch == ($choice | str trim) | first
  } else {
    # Direct selection mode
    let matches = $worktrees | where branch == $branch
    if ($matches | is-empty) {
      error make {msg: $"Error: worktree '($branch)' not found"}
    }
    $matches | first
  }

  print $selected.path
}
