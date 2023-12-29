{ config, ... }:
let
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users = {
    mutableUsers = true;
    users.nregner = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]
        ++ ifTheyExist [ "docker" "libvirtd" "networkmanager" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDk7uVEehfyhAZUvZbvH5Kw85MzLyYqVdTOMBXsmBeLx"
      ];
    };
  };

  nix.settings.trusted-users = [ "nregner" ];

  security.sudo = {
    wheelNeedsPassword = false;
    # https://github.com/NixOS/nixpkgs/issues/118655#issuecomment-1537131599
    extraRules = [{
      users = [ "nregner" ];
      commands = [{
        command = "/run/current-system/sw/bin/nix-store";
        options = [ "NOPASSWD" ];
      }];
    }];
  };
}
