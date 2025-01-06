{ pkgs, ... }:
{
  imports = [
    ../lib
    ./fzf.nix
    ./tmux.nix
    ./vim.nix
    ./zsh.nix
  ];

  config = {
    programs.ssh = {
      enable = true;
      # https://docs.ssh.com/manuals/server-zos-user/64/disabling-agent-forwarding.html
      forwardAgent = false;
      # share connections
      controlMaster = "auto";
      controlPersist = "10m";
    };

    home.packages = with pkgs.unstable; [
      deploy-rs
      nix-tree
      nix-du
    ];

    nix.gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      frequency = "weekly";
    };
  };
}
