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
      enableDefaultConfig = false;
      matchBlocks."*" = {
        # https://docs.ssh.com/manuals/server-zos-user/64/disabling-agent-forwarding.html
        forwardAgent = false;
        # share connections
        controlMaster = "auto";
        controlPersist = "10m";
        sendEnv = [ "TMUX" ];
      };
    };

    home.packages = with pkgs.unstable; [
      nix-tree
      nix-du
      pik
    ];

    nix.gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      dates = "weekly";
    };
  };
}
