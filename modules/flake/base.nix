{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = with inputs.self.modules.nixos; [
      backup
      multiverse
      nh
      pki
      sops
      tailscale
    ];
  };

  flake.modules.darwin.base = {
    imports = with inputs.self.modules.darwin; [
      backup
      multiverse
      nh
      pki
      sops
      tailscale
    ];
  };

  flake.modules.homeManager.base = {
    imports = with inputs.self.modules.homeManager; [
      backup
      multiverse
      nh
      sops
    ];
  };
}
