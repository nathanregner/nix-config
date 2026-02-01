{ inputs, ... }:
{
  flake.modules.nixos.wayland = {
    imports = with inputs.self.modules.nixos; [
      niri
    ];
  };

  flake.modules.homeManager.wayland = {
    imports = with inputs.self.modules.homeManager; [
      niri
      swww
    ];
  };
}

{ inputs, ... }:
{
  flake.modules.nixos.filename = {
    imports = with inputs.self.modules.nixos; [  ];
  };

  flake.modules.darwin.filename = {
    imports = with inputs.self.modules.darwin; [  ];
  };

  flake.modules.homeManager.filename = {
    imports = with inputs.self.modules.homeManager; [  ];
  };
}
