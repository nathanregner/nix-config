name="${1:-$(pwd)}"
target="$(mktemp -d)"

cp -lr "$name/.git" "$target/.bare"

pushd "$target"

echo "gitdir: ./.bare" >.git
git config core.bare true
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

popd

trash "$name"
mv "$target" "$name"

pushd "$name"

default_branch="$(basename "$(git symbolic-ref --short refs/remotes/origin/HEAD)")"
git worktree prune
git worktree add "../$default_branch"

popd
