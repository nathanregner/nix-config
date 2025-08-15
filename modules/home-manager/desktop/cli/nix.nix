{
  inputs,
  config,
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
    nix-diff
    nix-du
    nix-init
    nix-output-monitor
    nix-prefetch
    nix-tree
    nurl
    xdot
  ];

  # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/6
  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    ${pkgs.nvd}/bin/nvd diff $oldGenPath $newGenPath || true
  '';
}
