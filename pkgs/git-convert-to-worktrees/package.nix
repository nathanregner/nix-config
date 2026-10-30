{
  git,
  gitSetupHook,
  lib,
  nushell,
  runCommandLocal,
  symlinkJoin,
  trash-cli,
  writableTmpDirAsHomeHook,
  writers,
}:
let
  unwrapped = writers.writeNuBin "git-convert-to-worktrees" {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath [ trash-cli ]}"
    ];
  } ./convert-to-worktrees.nu;

  tests = lib.mapAttrs' (path: _: {
    name = lib.strings.replaceString ".nu" "" path;
    value =
      runCommandLocal "git-convert-to-worktrees-${path}"
        {
          nativeBuildInputs = [
            git
            nushell
            unwrapped
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
in
symlinkJoin {
  inherit (unwrapped) name meta;
  paths = [ unwrapped ];
  # Referencing the tests makes them build dependencies of the package itself
  checks = lib.attrValues tests;
  passthru = { inherit tests; };
}
