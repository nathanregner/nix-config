#!/usr/bin/env nu

def main [instance: string] {
  let dir = $"~/.factorio/instances/($instance)" | path expand
  mkdir $dir

  let config = mktemp -p /tmp
  [
    "[path]"
    "read-data=__PATH__system-read-data__"
    $"write-data=($dir)"
  ] | str join "\n" | save -f $config

  let exe = "~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio" | path expand
  /usr/bin/open -W -a $exe --args --config $config
}
