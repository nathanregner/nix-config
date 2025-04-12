#!/usr/bin/env bash
# See https://discourse.nixos.org/t/25274

prefix="$(readlink --canonicalize -- "$(dirname -- "$0")/packages")"
echo $prefix
nixpkgs="$(nix-instantiate --eval --expr '<nixpkgs>')"

nix-shell "$nixpkgs/maintainers/scripts/update.nix" \
  --arg include-overlays '(import ./. {}).nix-update-overlays' \
  --arg predicate "(
    let prefix = \"$prefix\"; prefixLen = builtins.stringLength prefix;
    in (_: p: (builtins.substring 0 prefixLen (p.meta.position or \"\")) == prefix)
  )" \
  --argstr package preprocess_cancellation
