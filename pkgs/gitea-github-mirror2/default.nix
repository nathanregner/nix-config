{ stdenvNoCC, babashka, bbin, clj-kondo, writeShellApplication, writeText, lib
}:
let script = ./main.clj;
in stdenvNoCC.mkDerivation {
  name = "gitea-github-mirror";
  nativeBuildInputs = [ babashka bbin clj-kondo ];
  src = lib.sources.sourceByRegex ./. [ ".*\\.clj" ];
  buildPhase = ''
    bb uberscript $out
    ls
  '';
  checkPhase = ''
    clj-kondo --config '{:linters {:namespace-name-mismatch {:level :off}}}' --lint ${script}
  '';
}
