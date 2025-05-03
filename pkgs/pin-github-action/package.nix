{
  fetchFromGitHub,
  buildNpmPackage,
  nix-update-script,
  writeShellScript,
}:

buildNpmPackage rec {
  pname = "pin-github-action";
  version = "3.3.1";

  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "v${version}";
    hash = "sha256-SPjQvHiAiknv0oILFrwGhyots5f1tyUpuyDgeQup9vQ=";
    fetchSubmodules = true;
  };

  npmDepsHash = "sha256-Y/fQK9jSyu+ZbVMALfz7K7MErTBSdw8RZTn6XRFolJo=";

  dontNpmBuild = true;

  passthru = {
    updateScript = nix-update-script { };
    # updateScript = [(writeShellScript "update" ''
    #   exec -a "$0" bash -c 'echo $0'
    # '')];
  };
}
