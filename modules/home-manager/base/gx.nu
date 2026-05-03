#!/usr/bin/env -S nu --stdin

# Input comes via stdin from tmux copy-pipe
def main [--editor] {
  let input = $in | str trim
  let open_cmd = if (which xdg-open | is-not-empty) { "xdg-open" } else { "open" }
  let editor_cmd = $env.EDITOR? | default "vim"

  # Try to extract URL from input
  let urls = $input | parse -r '(?P<url>https?://[^\s<>\"]+|www\.[^\s<>\"]+)'
  let url = if ($urls | is-empty) { "" } else { $urls | first | get url }

  if ($url | is-not-empty) and (not $editor) {
    ^$open_cmd $url
    return
  }

  # Try to extract file path
  let paths = $input | parse -r '(?P<path>~?/?[\w./=-]+)'
  let path_list = if ($paths | is-empty) { [] } else { $paths | get path }
  for p in $path_list {
    let expanded = $p | path expand
    if ($expanded | path exists) {
      if $editor {
        ^tmux send-keys $"($editor_cmd) '($expanded)'" Enter
      } else {
        ^$open_cmd $expanded
      }
      return
    }
  }

  # Fall back to Google search (only for non-editor mode)
  if not $editor {
    let query = $input | url encode
    ^$open_cmd $"https://www.google.com/search?q=($query)"
  }
}
