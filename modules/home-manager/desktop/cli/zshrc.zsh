case "$XDG_SESSION_TYPE" in
wayland)
  alias open='xdg-open'
  alias pbcopy='wl-copy'
  alias pbpaste='wl-paste'
  ;;
x11)
  alias open='xdg-open'
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
  ;;
esac
