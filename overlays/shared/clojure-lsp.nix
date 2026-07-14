prev: pkg:
pkg.overrideAttrs (oldAttrs: {
  nativeImageArgs = oldAttrs.nativeImageArgs ++ [
    "--enable-monitoring=jvmstat,heapdump,jfr"
  ];

  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.makeWrapper ];

  postInstall = (oldAttrs.postInstall or "") + ''
    wrapProgram $out/bin/${oldAttrs.meta.mainProgram} \
      --add-flags "-XX:+ExplicitGCInvokesConcurrent"
  '';
})
