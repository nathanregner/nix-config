{ fetchzip, stdenv }:
let
  version = "1.0.1";
  sources = {
    x86_64-linux = {
      url = "https://downloads.apache.org/maven/mvnd/${version}/maven-mvnd-${version}-linux-amd64.zip";
      hash = "sha256-PaPBKf1CCzO1QA98jl3zE2OfldfQOl/A2iZkeUllq+k=";
    };
    x86_64-darwin = {
      url = "https://downloads.apache.org/maven/mvnd/${version}/maven-mvnd-${version}-darwin-amd64.zip";
      hash = "sha256-yf+WBcOdOM3XsfiXJThVws2r84vG2jwfNV1c+sq6A4s=";
    };
    aarch64-darwin = {
      url = "https://downloads.apache.org/maven/mvnd/${version}/maven-mvnd-${version}-darwin-aarch64.zip";
      hash = "sha256-hhd8MnwKWpvG7UebkeEoztS45SJVnpvvJ9Zy+y5swik=";
    };
  };
in
stdenv.mkDerivation {
  pname = "mvnd";
  inherit version;
  src = fetchzip {
    inherit (sources.${stdenv.system} or (throw "Unsupported system: ${stdenv.system}")) url hash;
  };

  buildPhase = ''
    cp -r $src $out
  '';
}
