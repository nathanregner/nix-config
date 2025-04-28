{ pkgs, ... }:
{
  catppuccin.nushell.enable = true;

  programs.nushell = {
    enable = true;
  };

  programs.topiary = {
    # languages = [ pkgs.topiary-nushell ];
    languages = [
      (pkgs.runCommand "nu-language" { } ''
        mkdir $out
        cp ${./nu.scm} $out/nu.scm
      '')
    ];
    settings.languages.nu = {
      extensions = [ "nu" ];
      grammar.source.path = "${pkgs.tree-sitter-grammars.tree-sitter-nu}/parser";
    };
  };
}
