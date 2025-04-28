{ pkgs, ... }:
{
  programs.nushell = {
    enable = true;
    settings = {
      completions.external = {
        enable = true;
        max_results = 200;
      };
      edit_mode = "vi";
      show_banner = false;
    };
  };

  catppuccin.nushell.enable = true;

  # TODO: move to direnv file, = config.programs.nushell.enable
  programs.direnv.enableNushellIntegration = true;

  programs.topiary.languages.nu = {
    extensions = [ "nu" ];
    grammar.package = pkgs.tree-sitter-grammars.tree-sitter-nu;
    queries = ./nu.scm;
  };
}
