#!/usr/bin/env bash
set -euo pipefail

# Focus detection and notification script for Claude Code
# Sends notifications only when both tmux pane and Alacritty are unfocused

RATE_LIMIT_FILE="/tmp/claude-notify-last"
RATE_LIMIT_SECONDS=30

# Check rate limiting
check_rate_limit() {
  if [[ -f "$RATE_LIMIT_FILE" ]]; then
    last_notify=$(cat "$RATE_LIMIT_FILE")
    current_time=$(date +%s)
    time_diff=$((current_time - last_notify))

    if [[ $time_diff -lt $RATE_LIMIT_SECONDS ]]; then
      return 1  # Too soon, skip notification
    fi
  fi
  return 0  # OK to notify
}

# Update rate limit timestamp
update_rate_limit() {
  date +%s > "$RATE_LIMIT_FILE"
}

# Check if tmux pane is focused
check_tmux_focus() {
  if [[ -z "${TMUX:-}" ]]; then
    return 1  # Not in tmux, consider unfocused
  fi

  # Get pane_active status (1=focused, 0=unfocused)
  if pane_active=$(tmux display-message -p '#{pane_active}' 2>/dev/null); then
    if [[ "$pane_active" == "1" ]]; then
      return 0  # Tmux pane is focused
    fi
  fi

  return 1  # Tmux pane is unfocused
}

# Check if Alacritty is the frontmost application
check_alacritty_focus() {
  if frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null); then
    if [[ "$frontmost" == "Alacritty" ]]; then
      return 0  # Alacritty is focused
    fi
  fi

  return 1  # Alacritty is not focused
}

# Get tmux session info for notification
get_tmux_info() {
  if [[ -n "${TMUX:-}" ]]; then
    if session_info=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null); then
      echo "$session_info"
      return 0
    fi
  fi
  echo "terminal"
  return 0
}

# Send macOS notification
send_notification() {
  local subtitle="$1"

  osascript -e "display notification \"Claude Code is waiting for your input\" with title \"Claude Code\" subtitle \"Session: $subtitle\"" 2>/dev/null || true
}

# Main logic
main() {
  # Check if both tmux pane and Alacritty are unfocused
  tmux_focused=false
  alacritty_focused=false

  if check_tmux_focus; then
    tmux_focused=true
  fi

  if check_alacritty_focus; then
    alacritty_focused=true
  fi

  # Only notify if BOTH are unfocused
  if [[ "$tmux_focused" == "false" ]] && [[ "$alacritty_focused" == "false" ]]; then
    if check_rate_limit; then
      session_info=$(get_tmux_info)
      send_notification "$session_info"
      update_rate_limit

      # Optional: Return message to Claude Code (visible in logs)
      echo '{"systemMessage": "Notification sent (unfocused)"}'
    else
      echo '{"systemMessage": "Notification skipped (rate limited)"}'
    fi
  else
    echo '{"systemMessage": "Notification skipped (terminal focused)"}'
  fi
}

main "$@"
