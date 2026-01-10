#!/usr/bin/env nu

def main [instance: string] {
  let dir = $"~/.factorio/instances/($instance)" | path expand
  mkdir $dir

  let config = mktemp -p /tmp
  if (sys host).name == "macos" {
    [
      "[path]"
      "read-data=__PATH__system-read-data__"
      $"write-data=($dir)"
    ] | str join "\n" | save -f $config

    let exe = "~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio" | path expand
    /usr/bin/open -W -a $exe --args --config $config
  } else {
    [
      "[path]"
      $"read-data=("~/.factorio/data" | path expand)"
      # "read-data=__PATH__system-read-data__"
      $"write-data=($dir)"
    ] | str join "\n" | save -f $config
    cat $config
    # ^(~/.factorio/bin/x64/factorio | path expand) --config $config
    ^(~/.factorio/bin/x64/factorio | path expand) --config $config
  }
}
