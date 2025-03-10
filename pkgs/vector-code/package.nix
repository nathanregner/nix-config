{
  fetchFromGitHub,
  nix-update-script,
  python3,
  ...
}:
python3.pkgs.buildPythonApplication rec {
  pname = "vectorcode";
  version = "0.4.4";
  src = fetchFromGitHub {
    owner = "Davidyz";
    repo = "vectorcode";
    rev = "${version}";
    hash = "sha256-2TfeqQ6r+eCkeZjf4+WREyV/yeZUY7HsDlOAJYhpwa8=";
  };
  pyproject = true;

  nativeBuildInputs = with python3.pkgs; [
    # coverage
    # debugpy
    # ipython
    pdm-backend
    # pre-commit
    # pytest
    # pytest-asyncio
    # ruff
    # viztracer
  ];
  propagatedBuildInputs = with python3.pkgs; [
    chromadb
    httpx
    numpy
    pathspec
    psutil
    sentence-transformers
    shtab
    tabulate
  ];

  passthru.updateScript = nix-update-script { };
}
