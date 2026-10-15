prev: pkg:
let
  readPatches = root: map (path: root + "/${path}") (builtins.attrNames (builtins.readDir root));
in
# The version/hash bump below is only valid for the 3.7c base; fail loudly so it gets re-evaluated.
if pkg.version != "3.7c" then
  throw "overlays/shared/tmux: expected base tmux 3.7c but found ${pkg.version}; drop or update the 3.8 override"
else
  pkg.overrideAttrs (
    finalAttrs: oldAttrs: {
      version = "3.8";

      src = prev.fetchFromGitHub {
        owner = "tmux";
        repo = "tmux";
        tag = finalAttrs.version;
        hash = "sha256-pv2wlr3coo+E0pfpb58giJJQn9PGgMFqtVA6nk+9JdE=";
      };

      patches = (oldAttrs.patches or [ ]) ++ (readPatches ./patches);
    }
  )
