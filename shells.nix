{
  inputs',
  pkgs,
  treefmt,
}:
{
  default = pkgs.mkShellNoCC {
    packages = with pkgs.unstable; [
      age
      inputs'.deploy-rs.packages.default
      sops
      ssh-to-age
      tenv
      treefmt
    ];
  };

  bootstrap = pkgs.mkShellNoCC {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs.unstable; [
      nixVersions.latest
      git
    ];
    packages = [
      pkgs.generate-sops-keys
      inputs'.home-manager.packages.home-manager
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ inputs'.nix-darwin.packages.darwin-rebuild ];
  };
}
