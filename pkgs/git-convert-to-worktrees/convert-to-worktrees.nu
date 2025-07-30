def parse-porcelain [] {
  str trim
  | split row --regex '\n\n'
  | each {|row|
    $row
    | lines
    | each {|line| split row --number 2 " " }
    | reduce --fold {} {|entry, acc| $acc | insert $entry.0 $entry.1 }
  }
}

def setup-bare-repo [src: path] {
  cd $src
  let config = git config list --local
  | lines
  | where {|it| $it =~ '^(remote|branch)\.' }
  | each {|remote| remote | split row --number 2 "=" }

  let temp = mktemp -d $"(basename $src)-bare.XXXXXXXXXX" | path join ".git"
  git clone --bare --quiet $src $temp
  cd $temp
  git remote remove origin
  $config | each {|entry| git config set ...$entry }

  $temp
}

def copy-worktree [$bare: path, $worktree: record] {
  cd $bare
  let branch = $worktree.branch | str replace 'refs/heads/' ''
  let dest = $"../($branch)"

  git worktree add --relative-paths --quiet --force $dest $branch

  cd $dest
  git checkout $branch
  let temp = mktemp
  mv .git $temp
  cp -r ...(glob $"($worktree.worktree)/*") .
  rm -rf .git
  mv $temp .git

  $branch
}

def main [] {
  if (git --git-dir (git rev-parse --git-dir) rev-parse --is-bare-repository) == "true" {
    print -e "Nothing to do: already a bare repository"
    return
  }

  let src = (git rev-parse --show-toplevel)
  cd $src
  let worktrees = git worktree list --porcelain | parse-porcelain

  let bare = setup-bare-repo $src
  $worktrees | each {|worktree| copy-worktree $bare $worktree }

  trash -v $src
  cd # reset pwd
  mv ($bare | path join .. | path expand) $src

  $src
}
