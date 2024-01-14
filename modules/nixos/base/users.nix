{
  self,
  config,
  lib,
  ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.users.root.password = "root";
  services.openssh.settings.PasswordAuthentication = lib.mkForce false;

  users.users.nregner = {
    isNormalUser = true;
    extraGroups =
      [
        "wheel"
        "dialout"
      ]
      ++ ifTheyExist [
        "docker"
        "libvirtd"
        "networkmanager"
        "video"
      ];
    openssh.authorizedKeys.keys = builtins.attrValues self.globals.ssh.userKeys.nregner;
  };

  security.sudo = {
    wheelNeedsPassword = false;
    # https://github.com/NixOS/nixpkgs/issues/118655#issuecomment-1537131599
    extraRules = [
      {
        users = [ "nregner" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nix-store";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

}
