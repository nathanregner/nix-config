prev: pkg:
let
  inherit (prev) lib;
in
args:
[
  (prev.lib.getExe prev.nix-update)
  "--flake"
]
++ (lib.lists.tail (pkg args))
