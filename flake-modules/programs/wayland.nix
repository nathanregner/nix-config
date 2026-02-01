{ inputs, ... }:
{
  flake.modules.nixos.wayland = {
    imports = with inputs.self.modules.nixos; [
      niri
    ];
  };

  flake.modules.homeManager.wayland = {
    imports = with inputs.self.modules.homeManager; [
      hyprlock
      mako # notifications
      niri
      swww # wallpaper
      tofi # launcher
      waybar
    ];
  };
}
