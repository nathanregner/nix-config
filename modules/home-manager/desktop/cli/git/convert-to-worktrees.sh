name=$1
target=${2:-"$name.git"}
mkdir "$target"

cp -lr "$name/.git" "$target/.bare"

cd "$target"
echo "gitdir: ./.bare" >.git
git config core.bare true
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
