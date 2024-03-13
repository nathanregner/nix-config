# nix shell nixpkgs#cabal2nix.out -c cabal2nix /nix/store/.. > pkgs/update-nix-fetchgit.nix
{ mkDerivation, aeson, async, base, bytestring, data-fix, directory, filepath
, github-rest, hnix, lib, monad-validate, mtl, optparse-applicative
, optparse-generic, process, regex-tdfa, say, syb, tasty, tasty-discover
, tasty-golden, template-haskell, temporary, text, time, utf8-string, vector
, fetchFromGitHub }:
mkDerivation {
  pname = "update-nix-fetchgit";
  version = "0.2.11";
  src = fetchFromGitHub {
    owner = "expipiplus1";
    repo = "update-nix-fetchgit";
    rev = "345e49f2584c33d635685a6260905243377f9aba"; # master
    hash = "sha256-EC3kqt5NHyLJj01jDeu80gQ09ZNcmEO8aR8wuXMe+PA=";
  };
  isExecutable = true;
  libraryHaskellDepends = [
    aeson
    async
    base
    bytestring
    data-fix
    github-rest
    hnix
    monad-validate
    mtl
    process
    regex-tdfa
    syb
    template-haskell
    text
    time
    utf8-string
    vector
  ];
  executableHaskellDepends =
    [ base optparse-applicative optparse-generic regex-tdfa say text ];
  testHaskellDepends = [
    base
    directory
    filepath
    process
    tasty
    tasty-discover
    tasty-golden
    temporary
    text
  ];
  testToolDepends = [ tasty-discover ];
  homepage = "https://github.com/expipiplus1/update-nix-fetchgit#readme";
  description = "A program to update fetchgit values in Nix expressions";
  license = lib.licenses.bsd3;
  mainProgram = "update-nix-fetchgit";
}
