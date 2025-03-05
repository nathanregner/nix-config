# https://github.com/Hammerspoon/hammerspoon/tags
# https://github.com/NixOS/nixpkgs/pull/292296/files#diff-26375f4272499181f94d00c4f7cebcf92d12c67bc97f1b220ccf28ea79aed805
{
  lib,
  coreutils-prefixed,
  fetchFromGitHub,
  getopt,
  stdenvNoCC,
  unzip,
  which,
  xcbuild,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hammerspoon";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "Hammerspoon";
    repo = "hammerspoon";
    rev = finalAttrs.version;
    hash = "sha256-Uy6InmbUGcwEVo13yDhfRLX5RO2WM9UF+3EMhP7y4kM=";
  };

  nativeBuildInputs = [
    coreutils-prefixed
    getopt
    unzip
    which
    xcbuild
  ];

  patchPhase = ''
    patchShebangs ./scripts
    substituteInPlace ./scripts/build.sh \
      --replace-fail 'HAMMERSPOON_HOME="$(greadlink -f "''${SCRIPT_HOME}/../")"' 'HAMMERSPOON_HOME="$out"' \
      --replace-fail 'WEBSITE_HOME="$(greadlink -f "''${HAMMERSPOON_HOME}/../website")"' 'WEBSITE_HOME="$out/website"'
  '';

  env = {
    IS_CI = "1";
  };

  buildPhase = ''
    bash -x -o pipefail ./scripts/build.sh release -s Release -c Release
  '';

  installPhase = ''
    runHook preInstall

    runHook postInstall
  '';

  meta = with lib; {
    description = "Tool for powerful automation of macOS";
    longDescription = ''
      Hammerspoon is just a bridge between the operating system and a Lua scripting engine.
      What gives Hammerspoon its power is a set of extensions that expose specific pieces of system functionality, to the user.
    '';
    homepage = "http://www.hammerspoon.org";
    changelog = "http://www.hammerspoon.org/releasenotes/${finalAttrs.version}.html";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ nathanregner ];
    platforms = lib.platforms.darwin;
  };
}

)
