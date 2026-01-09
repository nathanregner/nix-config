{ ... }:
{
  programs.claude-code = {
    enable = true;

    # Define the notification script
    hooks.notify = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Read hook input from stdin
      input=$(cat)

      # Extract hook event name
      hook_event=$(echo "$input" | jq -r '.hook_event_name // "unknown"' 2>/dev/null || echo "unknown")

      RATE_LIMIT_FILE="/tmp/claude-notify-last"
      RATE_LIMIT_SECONDS=30

      # Check rate limiting
      check_rate_limit() {
        if [[ -f "$RATE_LIMIT_FILE" ]]; then
          last_notify=$(cat "$RATE_LIMIT_FILE")
          current_time=$(date +%s)
          time_diff=$((current_time - last_notify))

          if [[ $time_diff -lt $RATE_LIMIT_SECONDS ]]; then
            return 1
          fi
        fi
        return 0
      }

      # Update rate limit timestamp
      update_rate_limit() {
        date +%s > "$RATE_LIMIT_FILE"
      }

      # Check if tmux pane is focused
      check_tmux_focus() {
        if [[ -z "''${TMUX:-}" ]]; then
          return 1  # Not in tmux, consider unfocused
        fi

        if pane_active=$(tmux display-message -p '#{pane_active}' 2>/dev/null); then
          if [[ "$pane_active" == "1" ]]; then
            return 0  # Focused
          fi
        fi
        return 1  # Unfocused
      }

      # Check if Alacritty is frontmost
      check_alacritty_focus() {
        if frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null); then
          if [[ "$frontmost" == "Alacritty" ]]; then
            return 0  # Focused
          fi
        fi
        return 1  # Unfocused
      }

      # Get tmux session info
      get_tmux_info() {
        if [[ -n "''${TMUX:-}" ]]; then
          if session_info=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null); then
            echo "$session_info"
            return 0
          fi
        fi
        echo "terminal"
        return 0
      }

      # Send notification
      send_notification() {
        local title="$1"
        local message="$2"
        local subtitle="$3"
        osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\"" 2>/dev/null || true
      }

      # Main logic
      tmux_focused=false
      alacritty_focused=false

      if check_tmux_focus; then
        tmux_focused=true
      fi

      if check_alacritty_focus; then
        alacritty_focused=true
      fi

      # Only notify if both are unfocused
      if [[ "$tmux_focused" == "false" ]] && [[ "$alacritty_focused" == "false" ]]; then
        session_info=$(get_tmux_info)

        case "$hook_event" in
          "UserPromptSubmit")
            if check_rate_limit; then
              send_notification "Claude Code" "Waiting for your input" "Session: $session_info"
              update_rate_limit
              echo '{"systemMessage": "Notification sent (unfocused)"}'
            else
              echo '{"systemMessage": "Notification skipped (rate limited)"}'
            fi
            ;;

          "PermissionRequest")
            permission_type=$(echo "$input" | jq -r '.permission_type // "unknown"' 2>/dev/null || echo "unknown")
            tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null || echo "")

            if [[ -n "$tool_name" ]]; then
              send_notification "Claude Code Permission" "Requesting: $tool_name" "$session_info"
            else
              send_notification "Claude Code Permission" "Requesting: $permission_type" "$session_info"
            fi
            echo '{"systemMessage": "Permission notification sent"}'
            ;;

          *)
            echo '{"systemMessage": "Unknown hook event: '"$hook_event"'"}'
            ;;
        esac
      else
        echo '{"systemMessage": "Notification skipped (terminal focused)"}'
      fi
    '';

    # Register hooks to use the notify script
    settings.hooks = {
      UserPromptSubmit = {
        command = "notify";
        enabled = true;
      };
      PermissionRequest = {
        command = "notify";
        enabled = true;
      };
    };
  };
}
