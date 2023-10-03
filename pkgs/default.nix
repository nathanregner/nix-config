# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ inputs, pkgs }: {
  inherit (inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}) attic;
  route53-ddns = pkgs.unstable.callPackage ./route53-ddns { };
  # jetbrains-toolbox = pkgs.unstable.callPackage ./jetbrains-toolbox.nix { };

  # https://github.com/netdata/netdata/releases
  netdata-latest = pkgs.unstable.netdata.overrideAttrs (oldAttrs: rec {
    version = "1.42.4";

    src = pkgs.fetchFromGitHub {
      owner = "netdata";
      repo = "netdata";
      rev = "v${version}";
      hash = "sha256-8L8PhPgNIHvw+Dcx2D6OE8fp2+GEYOc9wEIoPJSqXME=";
      fetchSubmodules = true;
    };

    # FIXME: Typo in nixpkgs
    # enableParallelBuild = true;
    enableParallelBuilding = true;
  });

  # cross-compile heavy ARM on dependencies on more powerful x86 machines
  # TODO: Something more generic/flexible
  cross = import ./cross.nix {
    inherit inputs;
    localSystem = "x86_64-linux";
    crossSystem = "aarch64-multiplatform";
  };
}
