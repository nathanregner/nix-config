#!/usr/bin/env nu

def main [instance: string] {
  let dir = $"~/.factorio/instances/($instance)" | path expand
  mkdir $dir

  if (sys host).name == "macos" {
    let config = mktemp -p /tmp
    [
      "[path]"
      "read-data=__PATH__system-read-data__"
      $"write-data=($dir)"
    ] | str join "\n" | save -f $config

    let exe = "~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio" | path expand
    /usr/bin/open -W -a $exe --args --config $config
  } else {
    cp -r ~/.factorio/bin $"($dir)/bin"
    let config = $dir | path join "config" "config.ini"
    if ($config | path exists) == false {
      mkdir ($config | path dirname)
      cat ~/.factorio/config/config.ini
      | str replace --regex "read-data=.*" $"read-data=("~/.factorio/data" | path expand)"
      | str replace --regex "write-data=.*" $"write-data=($dir)"
      | save -f $config
    }

    exec $"($dir)/bin/x64/factorio" --config $config
  }
}
