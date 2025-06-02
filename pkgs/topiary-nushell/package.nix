{
  stdenv,
  fetchFromGitHub,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "topiary-nushell";
  version = "0-unstable-2025-04-25";
  src = fetchFromGitHub {
    owner = "blindFS";
    repo = "topiary-nushell";
    rev = "7f836bc14e0a435240c190b89ea02846ac883632";
    hash = "sha256-AkqgF7RShlmbc4i0Uv60LSyBcTt5njxr6jggvaZsK/s=";
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = "cp -pr --reflink=auto -- languages $out";

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [ "--version=branch" ];
    };
  };
}
