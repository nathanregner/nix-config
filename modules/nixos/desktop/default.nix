{ pkgs, ... }:
{
  imports = [
    ../base
    ./fhs.nix
    ./nix.nix
  ];

  users.mutableUsers = true;

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
  };
  environment.pathsToLink = [ "/share/zsh" ]; # as required by home-manager
  users.users.nregner.shell = pkgs.zsh; # login shell
}
