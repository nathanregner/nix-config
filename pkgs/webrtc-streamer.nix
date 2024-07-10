{
  abseil-cpp,
  cmake,
  live555,
  openssl,
  stdenv,
  webrtc,
  webrtc-streamer,
}:
stdenv.mkDerivation (
  webrtc-streamer
  // {

    postUnpack = ''
      mkdir -p ./webrtc/src
      cp -r ${webrtc.src}/* ./webrtc/src
      export WEBRTCROOT=$(pwd)/webrtc
      export LIVE=${live555.src}
    '';

    postPatch = ''
      substituteInPlace live555helper/CMakeLists.txt \
        --replace-fail 'set(LIVE ''${CMAKE_BINARY_DIR}/live)' 'set(LIVE "${live555.src}")'
    '';

    extraCmakeFlags = [
      # "-DWEBRTCROOT=${placeholder "$WEBRTCROOT"}/src"
      "-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
      "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY"
      "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY"
      "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY"
      "-DWEBRTCDESKTOPCAPTURE=OFF"
    ];

    strictDeps = true;

    nativeBuildInputs = [
      abseil-cpp
      cmake
    ];

    enableParallelBuilding = true;

    passthru = {
      webrtc = webrtc.src;
    };

    buildInputs = [ openssl ];
    # meta = with lib; {
    #   description = "Generate Terraform moved blocks automatically for painless refactoring";
    #   homepage = "https://github.com/busser/tfautomv";
    #   license = licenses.asl20;
    #   # maintainers = with maintainers; [];
    #   mainProgram = "tfautomv";
    # };
  }
)
