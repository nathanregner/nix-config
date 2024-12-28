{ config, pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    package = pkgs.unstable.alacritty;
    # https://alacritty.org/config-alacritty.html
    settings = {
      env = {
        TERM = "alacritty";
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 11;
      };
      general.import = [
        "${config.catppuccin.sources.alacritty}/catppuccin-${config.catppuccin.alacritty.flavor}.toml"
      ];
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
      selection = {
        save_to_clipboard = true;
      };
      # http://www.leonerd.org.uk/hacks/fixterms/
      window = {
        dynamic_padding = true;
        # https://github.com/alacritty/alacritty/issues/93
        option_as_alt = "Both";
      };
    };
  };
}
