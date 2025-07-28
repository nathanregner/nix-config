use std/assert

def main [out: string] {
  mkdir $out
  cd $out

  git init -b master

  touch master.txt
  git add -A
  git commit -m "initial commit"
  touch untracked.txt .untracked

  git worktree add -B a (mktemp -d)
  git branch b

  cd (git-convert-to-worktrees)

  cd .git
  assert equal (git rev-parse --is-bare-repository) "true"
  assert equal (git branch | lines) [
    "+ a"
    "  b"
    "* master"
  ]
  ls

  cd ../master
  assert equal (git rev-parse --abbrev-ref HEAD) "master"
  cat .untracked master.txt untracked.txt

  cd ../a
  assert equal (git rev-parse --abbrev-ref HEAD) "a"
}
