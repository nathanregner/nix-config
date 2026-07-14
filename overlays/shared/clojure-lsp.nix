prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  nativeImageArgs = oldAttrs.nativeImageArgs ++ [
    "--enable-monitoring=jvmstat,heapdump,jfr"
  ];
})
