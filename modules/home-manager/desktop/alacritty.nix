{ inputs, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ "${inputs.catppuccin-alacritty}/catppuccin-mocha.yml" ];
      selection = { save_to_clipboard = true; };
      window = { dynamic_padding = true; };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 11;
      };
      env = { TERM = "alacritty"; };
    };
  };
}
