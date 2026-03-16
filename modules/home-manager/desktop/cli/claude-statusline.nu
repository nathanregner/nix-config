#!/usr/bin/env -S nu --stdin
# Claude Code status line script

def model-name [] {
  $in
  | parse --regex 'claude-(?<name>\w+)-(?<major>\d)-(?<minor>\d)'
  | each { $"($in.name | str title-case) ($in.major).($in.minor)" }
  | first
  | default $in
}

def main [] {
  let input = $in | from json

  # Terminal width minus Claude Code's UI padding and emoji width buffer
  let term_width = (term size).columns - 6

  let model = $input | get -o model.display_name | model-name | default "unknown"
  let cost = $input | get -o cost.total_cost_usd | default 0
  let pct = $input | get -o context_window.used_percentage | default 0 | math round | into int
  let duration_ms = $input | get -o cost.total_duration_ms | default 0

  # Bar color based on context usage
  let bar_color = if $pct >= 90 { (ansi red) } else if $pct >= 70 { (ansi yellow) } else { (ansi reset) }

  # Progress bar
  let filled = $pct // 10
  let empty = 10 - $filled

  let bar = ("▓" | fill -c "▓" -w $filled) + ("░" | fill -c "░" -w $empty)

  # Duration
  let mins = $duration_ms // 60000
  let secs = ($duration_ms mod 60000) // 1000

  # Git branch
  # let branch = do { git branch --show-current } | complete | if $in.exit_code == 0 { $" |  ($in.stdout | str trim)" } else { "" }
  let branch = ""

  # Cost format
  let cost_fmt = $"$($cost | into string -d 2)"

  print -n $"[($model)]($branch) ($bar_color)($bar)(ansi reset) ($pct)% | ($cost_fmt) | ⏱️($mins)m ($secs)s"
}
