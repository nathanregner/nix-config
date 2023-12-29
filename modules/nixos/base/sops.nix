{ inputs, lib, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];
  sops.age.sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.gnupg.sshKeyPaths = lib.mkDefault [ ];
}
