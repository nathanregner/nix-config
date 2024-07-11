{
  inputs',
  pkgs,
  treefmt,
}:
{
  default = pkgs.mkShell {
    packages = with pkgs.unstable; [
      node2nix
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
    packages = [
      inputs'.home-manager.packages.home-manager
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ inputs'.nix-darwin.packages.darwin-rebuild ];
  };
}
