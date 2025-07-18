{
  inputs',
  pkgs,
  config,
}:
{
  default = pkgs.devshell.mkShell {
    packagesFrom = [
      config.treefmt.build.devShell
    ];
    packages = with pkgs.unstable; [
      inputs'.deploy-rs.packages.default
      local.generate-sops-keys
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
    packages =
      with pkgs.unstable;
      [
        nixVersions.latest
        git
        pkgs.local.generate-sops-keys
        inputs'.home-manager.packages.home-manager
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ inputs'.nix-darwin.packages.darwin-rebuild ];
  };
}
