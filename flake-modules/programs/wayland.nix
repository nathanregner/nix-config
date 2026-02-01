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
      niri
      swww
      tofi
    ];
  };
}
