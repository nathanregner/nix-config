{
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    (pkgs.writers.writeNuBin "nix-add-gc-roots" ./nix-add-gc-roots.nu)
    deploy-rs
    dix
    nix-du
    nix-output-monitor
    nix-prefetch
    nix-tree
  ];
}
