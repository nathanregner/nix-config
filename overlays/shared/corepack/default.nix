prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
    prev.installShellFiles
  ];
  installPhase = ''
    ${oldAttrs.installPhase or ""}
    installShellCompletion --cmd pnpm \
      --zsh ${./_pnpm}
  '';
})
