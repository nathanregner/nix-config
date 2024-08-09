{ self, lib, ... }:
{
  networking.firewall.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  };

  programs.ssh.knownHosts = self.globals.ssh.knownHosts;

  # sudo ssh -v builder@enceladus-linux-vm
  # sudo ssh -J nregner@enceladus builder@localhost -p 31022 -i /etc/ssh/ssh_host_ed25519_key
  programs.ssh.extraConfig = ''
    Host enceladus-linux-vm
      ProxyJump nregner@enceladus
      User builder
      HostName localhost
      Port 31022
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentityFile ~/.ssh/id_ed25519
  '';
}
