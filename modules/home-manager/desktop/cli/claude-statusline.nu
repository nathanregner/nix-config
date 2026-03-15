#!/usr/bin/env -S nu --stdin
# Claude Code status line script

def main [] {
  let input = $in | from json

  # Terminal width minus Claude Code's UI padding and emoji width buffer
  let term_width = (term size).columns - 6

  let model = $input | get -o model.display_name | default "unknown"
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

  # Build left and right parts
  let left = $"[($model)]($branch) ($bar_color)($bar)(ansi reset) ($pct)%"
  let right = $"($cost_fmt) | ⏱️($mins)m ($secs)s"

  # Calculate padding (subtract visible chars, not ANSI codes)
  let left_visible = $"[($model)]($branch) ($bar) ($pct)%"
  let padding = $term_width - ($left_visible | str stats).unicode-width - ($right | str stats).unicode-width
  let pad_str = if $padding > 0 { "" | fill -c " " -w $padding } else { " " }

  # Output
  print -n $"($left)($pad_str)($right)"
}
