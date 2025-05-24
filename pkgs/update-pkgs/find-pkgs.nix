# derived from <nixpkgs>/maintainers/scripts/update.nix
{ lib, pkgs }:
let
  get-script = pkg: pkg.updateScript or null;

  # Remove duplicate elements from the list based on some extracted value. O(n^2) complexity.
  nubOn =
    f: list:
    if list == [ ] then
      [ ]
    else
      let
        x = lib.head list;
        xs = lib.filter (p: f x != f p) (lib.drop 1 list);
      in
      [ x ] ++ nubOn f xs;

  /*
    Recursively find all packages (derivations) in `pkgs` matching `cond` predicate.

    Type: packagesWithPath :: AttrPath → (AttrPath → derivation → bool) → AttrSet → List<AttrSet{attrPath :: str; package :: derivation; }>
          AttrPath :: [str]

    The packages will be returned as a list of named pairs comprising of:
      - attrPath: stringified attribute path (based on `rootPath`)
      - package: corresponding derivation
  */
  packagesWithPath =
    rootPath: cond: pkgs:
    let
      packagesWithPathInner =
        path: pathContent:
        let
          result = builtins.tryEval pathContent;

          somewhatUniqueRepresentant =
            { package, ... }:
            {
              updateScript = get-script package;
              # Some updaters use the same `updateScript` value for all packages.
              # Also compare `meta.description`.
              position = package.meta.position or null;
              # We cannot always use `meta.position` since it might not be available
              # or it might be shared among multiple packages.
            };

          dedupResults = lst: nubOn somewhatUniqueRepresentant (lib.concatLists lst);
        in
        if result.success then
          let
            evaluatedPathContent = result.value;
          in
          if lib.isDerivation evaluatedPathContent then
            lib.optional (cond path evaluatedPathContent) {
              attrPath = lib.concatStringsSep "." path;
              package = evaluatedPathContent;
            }
          else if lib.isAttrs evaluatedPathContent then
            # If user explicitly points to an attrSet or it is marked for recursion, we recur.
            if
              path == rootPath
              || evaluatedPathContent.recurseForDerivations or false
              || evaluatedPathContent.recurseForRelease or false
            then
              dedupResults (
                lib.mapAttrsToList (name: elem: packagesWithPathInner (path ++ [ name ]) elem) evaluatedPathContent
              )
            else
              [ ]
          else
            [ ]
        else
          [ ];
    in
    packagesWithPathInner rootPath pkgs;

  # Recursively find all packages under `path` in `pkgs` with updateScript.
  packagesWithUpdateScript =
    _path: pkgs: packagesWithPath [ ] (_path: pkg: (get-script pkg != null)) pkgs;

  packages = packagesWithUpdateScript "." pkgs;

  packageData =
    { package, attrPath }:
    let
      updateScript = get-script package;
    in
    {
      name = updateScript.attrPath or attrPath;
      value = {
        inherit (package) name;
        pname = lib.getName package;
        oldVersion = lib.getVersion package;
        updateScript = map builtins.toString (lib.toList (updateScript.command or updateScript));
        supportedFeatures = updateScript.supportedFeatures or [ ];
        attrPath = updateScript.attrPath or attrPath;
      };
    };
in
builtins.listToAttrs (map packageData packages)
