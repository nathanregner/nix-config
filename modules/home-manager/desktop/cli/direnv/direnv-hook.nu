#!/usr/bin/env -S nu --stdin

def main [] {
  let input = $in | from json

  if $input.tool_name? != "Bash" {
    return
  }

  let working_dir = $input.working_directory
  let command = $input.tool_input.command
  let wrapped = $"direnv exec ($working_dir) bash -c ($command | to json)"

  print ({tool_input: {command: $wrapped}} | to json)
}
