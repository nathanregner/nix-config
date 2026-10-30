{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = with inputs.self.modules.nixos; [
      multiverse
      nh
      pki
      sops
      tailscale
    ];
  };

  flake.modules.darwin.base = {
    imports = with inputs.self.modules.darwin; [
      multiverse
      nh
      pki
      sops
      tailscale
    ];
  };

  flake.modules.homeManager.base = {
    imports = with inputs.self.modules.homeManager; [
      multiverse
      nh
      sops
    ];
  };
}
