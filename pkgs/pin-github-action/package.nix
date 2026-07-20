{
  fetchFromGitHub,
  buildNpmPackage,
  nix-update-script,
}:

buildNpmPackage rec {
  pname = "pin-github-action";
  version = "3.5.1";

  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "v${version}";
    hash = "sha256-wN2BXKr1lmxLiNIbA2ptuSQq3IgV2UlS0X3DMgL7Vc8=";
    fetchSubmodules = true;
  };

  npmDepsHash = "sha256-Qg1ImL1BbvN3VSP1cMw1fpb54yvD/N3gAq5VFE/cNl8=";

  dontNpmBuild = true;

  passthru = {
    updateScript = nix-update-script { };
    # updateScript = [(writeShellScript "update" ''
    #   exec -a "$0" bash -c 'echo $0'
    # '')];
  };

  meta.platforms = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
}
