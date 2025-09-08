#!/usr/bin/env nu
let windows = (niri msg --json windows | from json)

let index = $windows
| each {|w| $w.title }
| str join "\n"
| fuzzel --counter --dmenu --index

if $index != "" {
  niri msg action focus-window --id ($windows | get ($index | into int) | get id)
}
