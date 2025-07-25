{
  git,
  gitSetupHook,
  lib,
  nushell,
  runCommandLocal,
  trash-cli,
  writableTmpDirAsHomeHook,
  writers,
}:
let
  pkg = writers.writeNuBin "git-convert-to-worktrees" {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath [ trash-cli ]}"
    ];
  } ./convert-to-worktrees.nu;
in
pkg
// {
  passthru.tests = lib.mapAttrs' (path: _: {
    name = lib.strings.replaceString ".nu" "" path;
    value =
      runCommandLocal "git-convert-to-worktrees-${path}"
        {
          nativeBuildInputs = [
            git
            nushell
            pkg
            writableTmpDirAsHomeHook
            gitSetupHook
            # addBinToPathHook
          ];
        }
        ''
          mkdir $out
          nu ${./tests + "/${path}"} $out
        '';
  }) (builtins.readDir ./tests);
}
