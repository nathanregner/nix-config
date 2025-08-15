#!/usr/bin/env nix-shell
#! nix-shell -i nu -p nushell nix-prefetch-github common-updater-scripts

use std/log

let version_info = $"($env.FILE_PWD)/version.toml"

let current_version = open $version_info

let latest_version = list-git-tags --url=https://github.com/Kotlin/kotlin-lsp
| lines
| each {|it| $it | parse --regex 'v(?<version>[\d.]+)' } | flatten | each {|it| $it | get version }
| sort --natural
| last

if $current_version.version == $latest_version {
  log info "No update available"
  exit 0
}

let url = $"https://download-cdn.jetbrains.com/kotlin-lsp/($latest_version)/kotlin-($latest_version).zip"
log info $"nix-prefetch-url ($url)"

let hash = nix-prefetch-url $url
| nix-hash --type sha256 --to-base64 $in
| ["sha256-" $in]
| str join

{
  version: $latest_version
  url: $url
  hash: $hash
}
| to toml
| save $version_info -f
