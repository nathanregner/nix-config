{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # https://starship.rs/config
    settings = {
      aws.disabled = true;
      nix_shell = {
        symbol = "❄️";
        heuristic = true;
      };
      docker_context.only_with_files = false;
      package.disabled = true;

      # FIXME: IFD
      # catppuccin.starship.enable = false;
      # nix build .\#homeConfigurations.nregner@enceladus.config.catppuccin.sources.starship.src
      # nix eval --impure --expr 'builtins.fromTOML (builtins.readFile ./result/themes/mocha.toml)'
      format = lib.mkDefault "$all";
      palette = "catppuccin_mocha";
      palettes.catppuccin_mocha = {
        base = "#1e1e2e";
        blue = "#89b4fa";
        crust = "#11111b";
        flamingo = "#f2cdcd";
        green = "#a6e3a1";
        lavender = "#b4befe";
        mantle = "#181825";
        maroon = "#eba0ac";
        mauve = "#cba6f7";
        overlay0 = "#6c7086";
        overlay1 = "#7f849c";
        overlay2 = "#9399b2";
        peach = "#fab387";
        pink = "#f5c2e7";
        red = "#f38ba8";
        rosewater = "#f5e0dc";
        sapphire = "#74c7ec";
        sky = "#89dceb";
        subtext0 = "#a6adc8";
        subtext1 = "#bac2de";
        surface0 = "#313244";
        surface1 = "#45475a";
        surface2 = "#585b70";
        teal = "#94e2d5";
        text = "#cdd6f4";
        yellow = "#f9e2af";
      };
    };
  };
}
