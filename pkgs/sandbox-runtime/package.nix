{
  lib,
  bubblewrap,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  nix-update-script,
  ripgrep,
  socat,
  stdenv,
}:
buildNpmPackage {
  pname = "sandbox-runtime";
  version = "0.0.77";

  src = fetchFromGitHub {
    owner = "anthropic-experimental";
    repo = "sandbox-runtime";
    rev = "v0.0.77";
    hash = "sha256-iZtwX8S/8At2ZcCBSyf7v1GkLh5wDJvgsAXQz4rviTE=";
  };

  npmDepsHash = "sha256-q7chM6jxnE1MyC/EcgYYSrqufWgwM+NVPoWIH/u53lM=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/srt \
      --prefix PATH : ${
        lib.makeBinPath (
          [ ripgrep ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A lightweight sandboxing tool for enforcing filesystem and network restrictions";
    homepage = "https://github.com/anthropic-experimental/sandbox-runtime";
    license = lib.licenses.asl20;
    mainProgram = "srt";
    platforms = lib.platforms.unix;
  };
}
