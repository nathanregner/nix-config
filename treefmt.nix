{ pkgs }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt = {
      enable = true;
      excludes = [
        "pkgs/node2nix/*"
      ];
    };
    prettier = {
      enable = true;
      excludes = [
        "**/*-lock.json"
        "**/secrets.yaml"
        "dashboards/*.json"
      ];
    };
    shfmt.enable = true;
    stylua.enable = true;
    taplo.enable = true;
    terraform.enable = true;
  };

  settings.formatter = {
    joker = {
      command = "${pkgs.bash}/bin/bash";
      options = [
        "-euc"
        ''
          for file in "$@"; do
            ${pkgs.joker}/bin/joker --format $file | ${pkgs.moreutils}/bin/sponge $file
          done
        ''
        "--" # bash swallows the second argument when using -c
      ];
      includes = [ "*.clj" ];
    };
  };
}
