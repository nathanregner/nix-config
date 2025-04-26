#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl common-updater-scripts

set -eu -o pipefail

get() {
  curl -s ${GITHUB_TOKEN:+" -u \":$GITHUB_TOKEN\""} "$@"
}

branch=orangepi-6.1-rk35xx
ref=$(get "https://api.github.com/repos/orangepi-xunlong/linux-orangepi/git/refs/heads/$branch")
rev=$(jq '.object.sha' -r <<<"$ref")
url=$(jq '.object.url' -r <<<"$ref")
commit=$(get "$url")
date=$(jq '.committer.date | capture("(?<date>[0-9.-]+)T.*").date' -r <<<"$commit")

update-source-version linux-orangepi-6_1-rk35xx 6.1-rk3588 --ignore-same-version --file=pkgs/linux-orangepi-6_1-rk35xx/package.nix --rev="$rev"
