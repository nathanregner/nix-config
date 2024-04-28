{
  options,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../lib
    ./fzf.nix
    ./nix.nix
    ./tmux.nix
    ./vim.nix
    ./zsh.nix
  ];

  config = lib.mkMerge [
    {
      programs.ssh = {
        enable = true;
        # https://docs.ssh.com/manuals/server-zos-user/64/disabling-agent-forwarding.html
        forwardAgent = false;
        # share connections
        controlMaster = "auto";
        controlPersist = "10m";
      };

      home.packages = with pkgs.unstable; [
        nix-tree
        nix-du
      ];
    }
    # TODO: Remove check when home-manager is updated to 24.11
    (lib.optionalAttrs (builtins.hasAttr "gc" options.nix) {
      nix.gc = {
        automatic = true;
        options = "--delete-older-than 7d";
        frequency = "weekly";
      };
    })
  ];
}
