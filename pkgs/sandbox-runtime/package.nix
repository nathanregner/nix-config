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
  version = "0.0.75";

  src = fetchFromGitHub {
    owner = "anthropic-experimental";
    repo = "sandbox-runtime";
    rev = "v0.0.75";
    hash = "sha256-TfxVceVav2zw2L6D1hbQWOzVQZ4v/hZLollKysqZnKQ=";
  };

  npmDepsHash = "sha256-I7ebBTyRMBLmKE5wB8VEvKlB3Tjx2rbaKLFdMt0wbmg=";

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
