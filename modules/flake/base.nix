{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = with inputs.self.modules.nixos; [ ];
  };

  flake.modules.darwin.base = {
    imports = with inputs.self.modules.darwin; [ ];
  };

  flake.modules.homeManager.base = {
    imports = with inputs.self.modules.homeManager; [ ];
  };
}
