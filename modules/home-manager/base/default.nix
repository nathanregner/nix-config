{ inputs, pkgs, ... }:
{
  imports = [
    ../lib
    ./fzf.nix
    ./tmux.nix
    ./vim.nix
    ./zsh.nix
  ]
  ++ (with inputs.self.modules.homeManager; [
    base
  ]);

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
      nix-du
      nix-sweep
      nix-tree
      pik
    ];
  };
}
