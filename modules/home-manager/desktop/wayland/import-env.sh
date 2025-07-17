# https://github.com/hyprwm/Hyprland/discussions/3098#discussioncomment-6845577

set -e

_envs=(
  # display
  WAYLAND_DISPLAY
  DISPLAY
  # xdg
  USERNAME
  XDG_BACKEND
  XDG_CURRENT_DESKTOP
  XDG_SESSION_TYPE
  XDG_SESSION_ID
  XDG_SESSION_CLASS
  XDG_SESSION_DESKTOP
  XDG_SEAT
  XDG_VTNR
  # hyprland
  HYPRLAND_CMD
  HYPRLAND_INSTANCE_SIGNATURE
  # sway
  SWAYSOCK
  # niri
  NIRI_SOCKET
  # misc
  XCURSOR_SIZE
  # toolkit
  _JAVA_AWT_WM_NONREPARENTING
  QT_QPA_PLATFORM
  QT_WAYLAND_DISABLE_WINDOWDECORATION
  GRIM_DEFAULT_DIR
  # ssh
  SSH_AUTH_SOCK
)

dbus-update-activation-environment "${_envs[@]}"
systemctl --user import-environment "${_envs[@]}"

# if [[ -n "$TMUX" ]]; then
for v in "${_envs[@]}"; do
  if [[ -n ${!v} ]]; then
    echo "tmux setenv -g $v ${!v}"
    tmux setenv -g "$v" "${!v}"
  fi
done
# fi
