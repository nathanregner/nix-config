{ inputs, ... }:
{
  flake.modules.nixos.multiverse = {
    imports = [ inputs.multiverse.nixosModules.default ];
    multiverse.enable = true;
  };

  flake.modules.darwin.multiverse = {
    imports = [ inputs.multiverse.darwinModules.default ];
    multiverse.enable = true;
  };

  flake.modules.homeManager.multiverse = {
    imports = [ inputs.multiverse.homeManagerModules.default ];
    multiverse.enable = true;
  };
}
