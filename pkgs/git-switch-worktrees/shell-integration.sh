# Git worktree switcher shell integration
wt() {
  local result
  if result=$(git-switch-worktrees "$@" 2>&1); then
    cd "$result" || return 1
  else
    echo "$result" >&2
    return 1
  fi
}

# An executable can't change the shell's cwd, so this has to be a function.
gwt() { wt "$@"; }
