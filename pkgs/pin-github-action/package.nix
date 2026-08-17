{
  fetchFromGitHub,
  buildNpmPackage,
  nix-update-script,
}:

buildNpmPackage rec {
  pname = "pin-github-action";
  version = "3.5.2";

  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "v${version}";
    hash = "sha256-k29f/8mBNgOjsPejLEn0UiczvawepeQtQjwesPqJPZc=";
    fetchSubmodules = true;
  };

  npmDepsHash = "sha256-RlmtwE6AUV6RnAIwGly1pnuLbcLJ7nbUxH6NHX0IGg0=";

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
