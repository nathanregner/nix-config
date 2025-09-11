set -e
set -o pipefail

git_root="$(git rev-parse --show-toplevel)"
out="$git_root/${1#/nix/store/*/}"

build="$(mktemp -d)"
cd "$build"

sync_config() {
  parse-config "$out/.config" >"$out/.config.json"
}
export sync_config

# make localmodconfig
_make="$(which make)"
make() {
  pushd "$KERNEL_SRC"
  "$_make" "O=${build}" "-j${NIX_BUILD_CORES:-8}" "$@"
  cp "$build/.config" "$out/.config"
  sync_config
  popd
}
export make

makenconfig() {
  pushd "$build"
  cp "$out/.config" .config
  make nconfig
  popd
}
export makeold

makelocal() {
  pushd "$build"
  rm -f .config
  make localmodconfig
  popd
}
export makelocal

makeold() {
  pushd "$build"
  cp "$out/.config" .config
  make oldconfig
  popd
}
export makeold
