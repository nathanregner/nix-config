{ pkgs }:
let
  inherit (pkgs) lib;
in
{
  projectRootFile = "flake.nix";

  programs = {
    # deadnix.enable = true;
    nixfmt.enable = true;
    prettier = {
      enable = true;
      excludes = [
        "**/*-lock.json"
        "**/secrets.yaml"
      ];
    };
    rustfmt.enable = true;
    shfmt.enable = true;
    statix.enable = true;
    stylua.enable = true;
    taplo.enable = true;
    terraform.enable = true;
  };

  settings.formatter = {
    joker = {
      command =
        pkgs.writers.writeNuBin "treefmt-joker"
          # nu
          ''
            def main [...paths: string] {
              for path in $paths {
                ${pkgs.joker}/bin/joker --format $path | complete | get stdout o> $path
              }
            }
          '';
      includes = [
        "*.clj"
        "*.edn"
      ];
    };
    rustfmt.options = [ "+nightly" ];
  };
}
