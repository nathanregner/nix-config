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
