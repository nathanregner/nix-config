#!/usr/bin/env nix-shell
#!nix-shell -i nu -p openssl apacheHttpd

use std log

let hosts = [
  "iapetus"
  "sagittarius"
  "print-farm"
  "voron"
]

def generate_password [] {
  openssl rand -base64 32 | str trim
}

def hash_password [password: string] {
  htpasswd -nbB "" $password | str replace --regex '^:' '' | str trim
}

def sops_get [path: string key: cell-path] {
  return (sops -d $path | from yaml | get -o $key)
}

def sops_path_expression [] {
  $in | into string | split row '.' | skip 1 | each { $'["($in)"]' } | str join ''
}

def sops_set [path: string key: cell-path value: string] {
  let current = sops_get $path $key
  if $current != $value {
    log info $"  old: ($current | to json)"
    log info $"  new: ($value | to json)"
    sops --set $"($key | sops_path_expression) ($value | to json)" $path
  }
}

# def "main restic-server" [] {
def main [] {
  log info "Generating restic server passwords and htpasswd entries..."

  mut htpasswd_entries = []

  for host in $hosts {
    let secrets = $"machines/($host)/secrets.yaml"
    log info $"Updating ($secrets)..."

    let key = $.restic.server.password
    mut password = sops_get $secrets $key

    if $password != null {
      log info $"  Reusing existing password"
    } else {
      log info $"  Generating new password"
      $password = generate_password
      sops_set $secrets $key $password
    }

    let hashed = hash_password $password
    $htpasswd_entries = $htpasswd_entries | append $"($host):($hashed)"
  }

  let htpasswd_content = $htpasswd_entries | sort | str join "\n"

  log info "Updating sagittarius/secrets.yaml"
  sops_set "machines/sagittarius/secrets.yaml" restic.server.htpasswd $htpasswd_content
}
