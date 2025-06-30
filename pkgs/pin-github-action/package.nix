{
  fetchFromGitHub,
  buildNpmPackage,
  nix-update-script,
}:

buildNpmPackage rec {
  pname = "pin-github-action";
  version = "3.4.0";

  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "v${version}";
    hash = "sha256-Q8UqkZroCnfRwvkzAS31VucwcvtDmYbGKIs8Mv+PHso=";
    fetchSubmodules = true;
  };

  npmDepsHash = "sha256-6q2Sahit3FZ1zxUsJOrk3s8DzpV8x/H0XHZNhxlmdZQ=";

  dontNpmBuild = true;

  passthru = {
    updateScript = nix-update-script { };
    # updateScript = [(writeShellScript "update" ''
    #   exec -a "$0" bash -c 'echo $0'
    # '')];
  };
}
