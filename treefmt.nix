{ pkgs }:
{
  projectRootFile = "flake.nix";

  programs = {
    deadnix.enable = true;
    nixfmt = {
      enable = true;
    };
    prettier = {
      enable = true;
      package = pkgs.unstable.nodejs.pkgs.prettier;
      excludes = [
        "**/*-lock.json"
        "**/secrets.yaml"
      ];
    };
    shfmt.enable = true;
    statix.enable = true;
    stylua.enable = true;
    taplo.enable = true;
    terraform.enable = true;
  };

  settings.formatter = {
    joker = {
      command = pkgs.writers.writeNuBin "treefmt-joker" ''
        def main [...paths: string] {
          for path in $paths {
            let contents = ${pkgs.joker}/bin/joker --format $path
            $contents | save -f $path
          }
        }
      '';
      includes = [ "*.clj" ];
    };
  };
}
