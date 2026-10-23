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
  version = "0.0.80";

  src = fetchFromGitHub {
    owner = "anthropic-experimental";
    repo = "sandbox-runtime";
    rev = "v0.0.80";
    hash = "sha256-/oTzDaOGa77xXnk4M5NIp/EFe0bP9mqHkqzbtO6XTXk=";
  };

  npmDepsHash = "sha256-0msuDUKUrDXiUvm888wNmzQcEzPpIw46wnB3eSsVG50=";

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
