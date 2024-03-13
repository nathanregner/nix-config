{ lib }: rec {
  warnIfOutdated = (curr: prev:
    lib.trivial.warnIfNot (lib.strings.versionAtLeast curr.version prev.version)
    "${curr.name} is outdated: ${curr.version} < prev ${prev.version}" curr);

  overrideAttrsWarnIfOutdated = drv: args:
    warnIfOutdated (drv.overrideAttrs args) drv;
}
