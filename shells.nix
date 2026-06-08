{
  inputs',
  config,
  pkgs,
}:
let
  inherit (pkgs) lib;
in
{
  default = pkgs.devshell.mkShell {
    packagesFrom = [
      config.treefmt.build.devShell
    ];
    packages = with pkgs.unstable; [
      # inputs'.deploy-rs.packages.default
      sops
      # tenv
    ];
  };

  terraform = pkgs.devshell.mkShell {
    packages = with pkgs.unstable; [
      opentofu
    ];
  };

  bootstrap = pkgs.devshell.mkShell {
    env = [
      {
        name = "NIX_CONFIG";
        value = "experimental-features = nix-command flakes";
      }
    ];
    packages = [
      inputs'.home-manager-unstable.packages.home-manager
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ inputs'.nix-darwin.packages.darwin-rebuild ];
  };
}
