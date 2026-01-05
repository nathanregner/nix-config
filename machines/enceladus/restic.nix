{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.restic = {
    enable = true;
    backups.test = {
      repository = "/tmp/test";
      passwordFile = "/tmp/password";
    };
  };

  home.packages = lib.mapAttrsToList (
    name: _:
    (pkgs.runCommand "restic-${name}-completions" { nativeBuildInputs = [ pkgs.installShellFiles ]; } ''
      cat > bash-completion <<EOF
      if ! declare -F _restic >/dev/null 2>&1; then
        source ${pkgs.restic}/share/bash-completion/completions/restic
      fi
      complete -F _restic restic-${name}
      EOF

      cat > zsh-completion <<EOF
      #compdef restic-${name}
      if (( ! \$+functions[_restic] )); then
        fpath+=(${pkgs.restic}/share/zsh/site-functions)
        autoload -Uz _restic
      fi
      _restic "\$@"
      EOF

      cat > fish-completion <<EOF
      if not functions -q __fish_restic_no_subcommand
        test -f ${pkgs.restic}/share/fish/vendor_completions.d/restic.fish && source ${pkgs.restic}/share/fish/vendor_completions.d/restic.fish
      end
      complete -c restic-${name} -w restic
      EOF

      installShellCompletion --cmd restic-${name} \
        --bash bash-completion \
        --zsh zsh-completion \
        --fish fish-completion
    '')
  ) config.services.restic.backups;

}
