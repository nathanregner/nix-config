{ inputs, ... }:
{
  flake.modules.nixos.sops =
    { lib, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];
      sops.age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

  flake.modules.darwin.sops =
    { lib, ... }:
    {
      imports = [ inputs.sops-nix.darwinModules.sops ];
      sops.age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

  flake.modules.homeManager.sops =
    { config, lib, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModule ];
      sops.age.sshKeyPaths = lib.mkDefault [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    };
}
