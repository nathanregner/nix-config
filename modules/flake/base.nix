{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = with inputs.self.modules.nixos; [
      nh
      sops
    ];
  };

  flake.modules.darwin.base = {
    imports = with inputs.self.modules.darwin; [
      nh
      sops
    ];
  };

  flake.modules.homeManager.base = {
    imports = with inputs.self.modules.homeManager; [
      nh
      sops
    ];
  };
}
