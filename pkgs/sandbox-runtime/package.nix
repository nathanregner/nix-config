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
  version = "0.0.79";

  src = fetchFromGitHub {
    owner = "anthropic-experimental";
    repo = "sandbox-runtime";
    rev = "v0.0.79";
    hash = "sha256-GnqdoiT5zIoTeDzDh7Ca3wwJYQsQs910JNEyg1zUdRo=";
  };

  npmDepsHash = "sha256-BW/L6JYuS0oYfZJ7LzPu7R3n4cmqzyMvVrM3UdzSdX4=";

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
