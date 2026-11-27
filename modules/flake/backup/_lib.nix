# Helpers shared by the backup adapters. Prefixed with `_` so import-tree skips it.
{ lib }:
let
  parseInterval =
    interval:
    let
      m = builtins.match "([0-9]+)([mhd])" interval;
    in
    if m == null then
      throw "local.services.backup: invalid interval '${interval}' (expected e.g. 30m, 6h, 1d)"
    else
      {
        n = lib.toInt (builtins.elemAt m 0);
        unit = builtins.elemAt m 1;
      };
in
rec {
  intervalType = lib.types.strMatching "[0-9]+[mhd]";

  toSeconds =
    interval:
    let
      i = parseInterval interval;
    in
    i.n
    * {
      m = 60;
      h = 3600;
      d = 86400;
    }
    .${i.unit};

  # systemd needs a calendar expression so that `Persistent` catches up on missed runs
  toOnCalendar =
    interval:
    let
      inherit (parseInterval interval) n unit;
      invalid = throw "local.services.backup: interval '${interval}' cannot be expressed as a systemd calendar event (must evenly divide an hour/day, or be 1d)";
    in
    if unit == "m" then
      (if n > 0 && 60 / n * n == 60 then "*-*-* *:00/${toString n}:00" else invalid)
    else if unit == "h" then
      (
        if n == 1 then
          "hourly"
        else if n > 0 && 24 / n * n == 24 then
          "*-*-* 00/${toString n}:00:00"
        else
          invalid
      )
    else if n == 1 then
      "daily"
    else
      invalid;

  toTimerConfig = interval: {
    OnCalendar = toOnCalendar interval;
    RandomizedDelaySec = "10m";
    Persistent = true;
  };

  # `restic-<name>` command with the repository/password environment preset
  mkWrapper =
    pkgs: package: name: backup:
    pkgs.writeShellApplication {
      name = "restic-${name}";
      runtimeInputs = [
        package
      ]
      ++ lib.optional (lib.hasPrefix "rclone:" backup.repository) pkgs.rclone;
      excludeShellChecks = [ "SC1091" ];
      text = ''
        ${lib.optionalString (backup.environmentFile != null) ''
          set -a
          source ${lib.escapeShellArg backup.environmentFile}
          set +a
        ''}
        export RESTIC_REPOSITORY=${lib.escapeShellArg backup.repository}
        export RESTIC_PASSWORD_FILE=${lib.escapeShellArg backup.passwordFile}
        exec restic "$@"
      '';
    };

  # Equivalent of the NixOS restic unit: init, backup, prune
  mkRunner =
    pkgs: wrapper: name: backup:
    let
      restic = lib.getExe wrapper;
    in
    pkgs.writeShellApplication {
      name = "restic-backups-${name}";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        ${lib.optionalString (backup.root != null) "cd ${lib.escapeShellArg backup.root}"}

        ${restic} cat config >/dev/null 2>&1 || ${restic} init

        files=$(mktemp)
        trap 'rm -f "$files"' EXIT
        ${lib.concatMapStrings (p: ''
          printf '%s\n' ${lib.escapeShellArg p} >>"$files"
        '') backup.paths}
        ${lib.optionalString (backup.dynamicFilesFrom != null) ''
          ${pkgs.writeShellScript "restic-${name}-dynamic-files" backup.dynamicFilesFrom} >>"$files"
        ''}

        ${restic} backup --skip-if-unchanged --files-from "$files" \
          --exclude-file ${pkgs.writeText "restic-${name}-exclude" (lib.concatLines backup.exclude)}

        ${lib.optionalString (backup.pruneOpts != [ ]) ''
          ${restic} forget --prune ${lib.concatStringsSep " " backup.pruneOpts}
        ''}
      '';
    };

  mkCompletions =
    pkgs: name: package:
    pkgs.runCommand "restic-${name}-completions" { nativeBuildInputs = [ pkgs.installShellFiles ]; } ''
      cat > bash-completion <<EOF
      if ! declare -F _restic >/dev/null 2>&1; then
        source ${package}/share/bash-completion/completions/restic
      fi
      complete -F _restic restic-${name}
      EOF

      cat > zsh-completion <<EOF
      #compdef restic-${name}
      if (( ! \$+functions[_restic] )); then
        fpath+=(${package}/share/zsh/site-functions)
        autoload -Uz _restic
      fi
      _restic "\$@"
      EOF

      cat > fish-completion <<EOF
      if not functions -q __fish_restic_no_subcommand
        test -f ${package}/share/fish/vendor_completions.d/restic.fish && source ${package}/share/fish/vendor_completions.d/restic.fish
      end
      complete -c restic-${name} -w restic
      EOF

      installShellCompletion --cmd restic-${name} \
        --bash bash-completion \
        --zsh zsh-completion \
        --fish fish-completion
    '';
}
