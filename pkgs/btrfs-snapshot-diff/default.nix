{
  sources,
  python3,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  inherit (sources.btrfs-snapshot-diff) pname version src;

  propagatedBuildInputs = [
    (python3.withPackages (
      pythonPackages: with pythonPackages; [
        btrfs
      ]
    ))
  ];

  dontUnpack = true;
  installPhase = "install -Dm755 ${src}/subvolume.py $out/bin/btrfs-snapshot-diff";
}
