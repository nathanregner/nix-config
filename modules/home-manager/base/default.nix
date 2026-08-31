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
      settings."Host *" = {
        # https://docs.ssh.com/manuals/server-zos-user/64/disabling-agent-forwarding.html
        ForwardAgent = false;
        # share connections
        ControlMaster = "auto";
        ControlPersist = "10m";
        SendEnv = [ "TMUX" ];
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
