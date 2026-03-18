{
  lib,
  bubblewrap,
  socat,
  ripgrep,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
  stdenv,
}:
buildNpmPackage rec {
  pname = "sandbox-runtime";
  version = "0.0.42";

  src = fetchFromGitHub {
    owner = "anthropic-experimental";
    repo = "sandbox-runtime";
    rev = "v${version}";
    hash = "sha256-aFLHY17wMpSmwpR0GmvBQZ2PL824PTTpfdZQFfR0hBs=";
  };

  npmDepsHash = "sha256-K9PttPaNAlPMylndDtNasnN+bgM1DQ3OLyP3aiLxfEQ=";

  strictDeps = true;

  postInstall = ''
    wrapProgram $out/bin/srt \
      --prefix PATH : ${
        lib.makeBinPath (
          lib.optionals stdenv.hostPlatform.isDarwin [
            ripgrep
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            ripgrep
          ]
        )
      }
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = " A lightweight sandboxing tool for enforcing filesystem and network restrictions on arbitrary processes at the OS level, without requiring a container. ";
    homepage = "https://github.com/anthropic-experimental/sandbox-runtime";
    license = lib.licenses.asl20;
    mainProgram = "srt";
  };
}
