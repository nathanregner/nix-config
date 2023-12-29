# source: https://github.com/cdepillabout/stacklock2nix/blob/65a34bec929e7b0e50fdf4606d933b13b47e2f17/nix/build-support/stacklock2nix/read-yaml.nix
{ pkgs, ... }: {
  config = {
    lib.formats.fromYAML = path:
      let
        jsonOutputDrv = pkgs.runCommand "from-yaml" {
          nativeBuildInputs = [ pkgs.remarshal ];
        } ''remarshal -if yaml -i "${path}" -of json -o "$out"'';
      in builtins.fromJSON (builtins.readFile jsonOutputDrv);
  };
}
