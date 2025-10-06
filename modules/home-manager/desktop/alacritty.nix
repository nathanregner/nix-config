{
  config,
  pkgs,
  lib,
  ...
}:
{
  catppuccin.alacritty.enable = true;
  programs.alacritty = {
    enable = true;
    package = pkgs.unstable.local.alacritty;
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
      # http://www.leonerd.org.uk/hacks/fixterms/
      selection = {
        save_to_clipboard = true;
      };
      terminal = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        shell = "${config.home.homeDirectory}/.nix-profile/bin/zsh";
      };
      window = {
        dynamic_padding = true;
        # https://github.com/alacritty/alacritty/issues/93
        option_as_alt = "Both";
      };
    };
  };
}
