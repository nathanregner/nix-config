{ inputs, lib, stdenv, cmake }:

stdenv.mkDerivation {
  pname = "rockchip-mpp";
  version = inputs.rockchip-mpp.rev;

  outputs = [ "out" "dev" ];

  src = inputs.rockchip-mpp;

  # strictDeps = true;
  enableParallelBuilding = true;

  dontFixup = true;

  # depsBuildBuild = [ pkg-config ];
  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "GStreamer Good Plugins";
    homepage = "https://gstreamer.freedesktop.org";
    longDescription = ''
      a set of plug-ins that we consider to have good quality code,
      correct functionality, our preferred license (LGPL for the plug-in
      code, LGPL or LGPL-compatible for the supporting library).
    '';
    license = licenses.lgpl2Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ matthewbauer lilyinstarlight ];
  };
}
