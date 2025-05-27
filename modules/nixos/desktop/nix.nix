{ inputs, ... }:
{
  nix.settings = {
    # keep build dependencies for direnv GC roots
    keep-derivations = true;
    keep-outputs = true;
  };
}
