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
      # http://www.leonerd.org.uk/hacks/fixterms/
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
        {
          mods = "Control|Shift";
          key = "Return";
          chars = "\\u001B[13;7u";
        }
      ];
    };
  };

  home.sessionVariables = {
    TERMINFO_DIRS = "${pkgs.alacritty.terminfo.outPath}/share/terminfo";
  };
}
