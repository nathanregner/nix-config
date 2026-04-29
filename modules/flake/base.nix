{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = with inputs.self.modules.nixos; [ nh ];
  };

  flake.modules.darwin.base = {
    imports = with inputs.self.modules.darwin; [ nh ];
  };

  flake.modules.homeManager.base = {
    imports = with inputs.self.modules.homeManager; [ nh ];
  };
}
