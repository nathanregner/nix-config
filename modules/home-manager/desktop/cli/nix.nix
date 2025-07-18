{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # https://github.com/nix-community/nix-direnv
    nix-direnv.enable = true;
  };

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
    nix-prefetch
    nix-tree
    nurl
  ];

  # https://discourse.nixos.org/t/nvd-simple-nix-nixos-version-diff-tool/12397/6
  home.activation.report-changes = config.lib.dag.entryAnywhere ''
    ${pkgs.nvd}/bin/nvd diff $oldGenPath $newGenPath || true
  '';
}
