{ pkgs, ... }:
let
  yaml = pkgs.formats.yaml { };
in
{
  home.packages = [
    pkgs.unstable.ast-grep
    # pkgs.unstable.tree-sitter
  ];

  home.file."sgconfig.yml" = {
    source = yaml.generate "sgconfig.yml" {
      customLanguages = {
        hcl = {
          extensions = [
            "hcl"
            "tf"
          ];
          libraryPath = "${pkgs.unstable.tree-sitter-grammars.tree-sitter-hcl}/parser";
        };
      };
      ruleDirs = [ ];
    };
    force = true;
  };
}
