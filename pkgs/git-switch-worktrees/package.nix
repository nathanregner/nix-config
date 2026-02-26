{
  installShellFiles,
  lib,
  git,
  fzf,
  writers,
}:
let
  pkg = writers.writeNuBin "git-switch-worktrees" {
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      "${lib.makeBinPath [ git fzf ]}"
    ];
  } ./switch-worktrees.nu;
in
pkg.overrideAttrs (oldAttrs: {
  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ installShellFiles ];

  postInstall = (oldAttrs.postInstall or "") + ''
    installShellCompletion --zsh ${./completions/_wt}
  '';

  passthru = (oldAttrs.passthru or { }) // {
    shellIntegration = ./shell-integration.sh;
  };
})
