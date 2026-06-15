envrc_path="$(realpath "$2")"
envrc_path="${envrc_path%/.envrc}"

: "${XDG_CACHE_HOME:="${HOME}/.cache"}"
declare -A direnv_layout_dirs
direnv_layout_dir() {
  echo "${direnv_layout_dirs[$envrc_path]:="${XDG_CACHE_HOME}/direnv/layouts$envrc_path"}"
}

# vim: set ft=bash:
