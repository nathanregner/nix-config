{
  lib,
  cargo,
  writers,
}:
drv:
{
  breaking ? true,
}:
[
  (writers.writeNu "update-cargo.lock" ''
    let position = echo '${drv.meta.position}' | parse --regex '/nix/store/\w+-source/(?<path>.*):\d+' | first
    cd ($position.path | path dirname)
      ${lib.getExe cargo} update ${lib.optionalString breaking "-Z unstable-options --breaking"}
  '')
]
