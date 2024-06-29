{
  inputs',
  pkgs,
  treefmt,
}:
{
  default = pkgs.mkShell {
    packages = with pkgs.unstable; [
      sops
      tenv
      treefmt
    ];
  };

  bootstrap = pkgs.mkShell {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs.unstable; [
      nix
      git
    ];
    packages = [ inputs'.home-manager.packages.home-manager ];
  };
}
