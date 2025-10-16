#!/usr/bin/env nu

def --wrapped main [...args] {
  let pwd = $env.PWD
  let workspace_dir = [
    $env.XDG_CACHE_HOME
    jdtls
    $"($pwd | hash sha256 | head -c40)-($pwd | path basename)"
  ] | path join

  # FIXME: doesn't work
  $env.MAVEN_OPTS = $"-DoutputDirectory=($workspace_dir)/maven/target"
  print -e $"MAVEN_OPTS=($env.MAVEN_OPTS)"

  exec jdtls -data $workspace_dir ...$args
}
