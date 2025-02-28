# https://github.com/Sohalt/write-babashka-application/blob/main/flake.nix
{
  babashka,
  clj-kondo,
  writeShellApplication,
  writeText,
}:
{
  name,
  text,
  runtimeInputs ? [ ],
  checkPhase ? null,
}:
let
  script = writeText "script.clj" text;
in
writeShellApplication {
  inherit name runtimeInputs;
  text = ''
    exec ${babashka}/bin/bb ${script} $@
  '';
  checkPhase = ''
    ${clj-kondo}/bin/clj-kondo --config '{:linters {:namespace-name-mismatch {:level :off}}}' --lint ${script}
  '';
}
