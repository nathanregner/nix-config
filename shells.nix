{
  inputs',
  pkgs,
  config,
}:
{
  default = pkgs.mkShellNoCC {
    inputsFrom = [
      config.treefmt.build.devShell
    ];
    packages = with pkgs.unstable; [
      inputs'.deploy-rs.packages.default
      local.generate-sops-keys
      sops
      tenv
    ];
  };

  bootstrap = pkgs.mkShellNoCC {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs.unstable; [
      nixVersions.latest
      git
    ];
    packages = [
      pkgs.local.generate-sops-keys
      inputs'.home-manager.packages.home-manager
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ inputs'.nix-darwin.packages.darwin-rebuild ];
  };
}
