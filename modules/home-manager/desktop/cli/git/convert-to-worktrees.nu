def setup-bare-repo [src: path] {
  let temp = mktemp -d
  cd $temp

  cp -r $"($src)/.git" ".git"
  "gitdir: ./.git" | save -f .git
  git config core.git true
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

  $temp
}

def add-default-worktree [$repo: path] {
  cd $repo

  let default_branch = git symbolic-ref --short refs/remotes/origin/HEAD | path basename
  git worktree prune
  git worktree add $default_branch
  $"gitdir: ../.git/worktrees/($default_branch)" | save -f $"($default_branch)/.git"

  $default_branch
}

def main [] {
  if (git rev-parse --is-bare-repository) == "true" {
    print "Nothing to do: already a bare repository"
    return
  }

  let src = (git rev-parse --show-toplevel)
  let temp = setup-bare-repo $src
  trash -v $src
  cd
  mv $temp $src

  let default_branch = add-default-worktree $src
  cd $"($src)/($default_branch)"
}
