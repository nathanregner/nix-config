{ fenix }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    rustfmt = {
      enable = true;
      package = fenix.latest.rustfmt;
    };
    statix.enable = true;
    taplo = {
      enable = true;
      settings = fromTOML (builtins.readFile ../../.taplo.toml);
    };
  };
}
