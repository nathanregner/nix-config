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
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      keyPath = "${config.home.homeDirectory}/.ssh/id_ed25519";
    in
    {
      imports = [ inputs.sops-nix.homeManagerModule ];
      sops.age.sshKeyPaths = lib.mkDefault [ keyPath ];

      home.sessionVariables.SOPS_AGE_KEY_CMD = pkgs.writers.writeBash "sops-age-key" {
        makeWrapperArgs = [
          "--prefix"
          "PATH"
          ":"
          "${lib.makeBinPath [
            pkgs.ssh-to-age
            pkgs.age
          ]}"
        ];
      } "ssh-to-age -private-key -i ${keyPath}";
    };
}
