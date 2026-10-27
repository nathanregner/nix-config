# Adds completions via a wrapper so the corepack build itself is not rebuilt.
prev: pkg:
prev.symlinkJoin {
  inherit (pkg) name meta;
  paths = [
    pkg
    (prev.runCommand "${pkg.name}-completions" { nativeBuildInputs = [ prev.installShellFiles ]; } ''
      installShellCompletion --cmd pnpm --zsh ${./_pnpm}
    '')
  ];
}
