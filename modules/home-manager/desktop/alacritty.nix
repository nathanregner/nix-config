{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    package = pkgs.unstable.alacritty;
    catppuccin.enable = true;
    settings = {
      selection = {
        save_to_clipboard = true;
      };
      window = {
        dynamic_padding = true;
        # https://github.com/alacritty/alacritty/issues/93
        option_as_alt = "Both";
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 11;
      };
      env = {
        TERM = "alacritty";
      };
      # https://stackoverflow.com/questions/16359878/how-to-map-shift-enter#comment124634141_42461580
      keyboard.bindings = [
        {
          mods = "Control";
          key = "Return";
          chars = "\\u001B[13;5u";
        }
        {
          mods = "Shift";
          key = "Return";
          chars = "\\u001B[13;2u";
        }
      ];
    };
  };
}
