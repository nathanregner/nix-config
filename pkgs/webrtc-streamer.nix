{
  abseil-cpp,
  clangStdenv,
  cmake,
  fetchgit,
  gn,
  jsoncpp,
  libyuv,
  live555,
  ninja,
  openssl,
  webrtc-streamer,
}:
let
  webrtc = fetchgit {
    url = "https://webrtc.googlesource.com/src";
    rev = "33e6e80acc43e6563334d9cafc523896a29bf8fb";
    fetchSubmodules = true;
    sha256 = "sha256-HvS7JPiiGj6xcoyQ0Tk+tIph/SU6iDdusshMPPwoPeY=";
  };
in
clangStdenv.mkDerivation (
  webrtc-streamer
  // {

    # TODO: https://github.com/NixOS/nixpkgs/blob/f00f4ce07e710140223200a88738661a2af984a2/pkgs/applications/science/math/yacas/jsoncpp-fix-include.patch#L9-L13
    # set (WEBRTCINCLUDE ${WEBRTCROOT}/src ${WEBRTCROOT}/src/third_party/abseil-cpp ${WEBRTCROOT}/src/third_party/jsoncpp/source/include  ${WEBRTCROOT}/src/third_party/jsoncpp/generated ${WEBRTCROOT}/src/third_party/libyuv/include)
    postUnpack = ''
      mkdir -p ./webrtc/src
      cp -r ${webrtc}/* ./webrtc/src
      mkdir -p ./webrtc/src/third_party/abseil-cpp
      cp -r ${abseil-cpp.src}/* ./webrtc/src/third_party/abseil-cpp
      mkdir -p ./webrtc/src/third_party/jsoncpp/source
      cp -r ${jsoncpp.src}/* ./webrtc/src/third_party/jsoncpp/source
      mkdir -p ./webrtc/src/third_party/libyuv
      cp -r ${libyuv.src}/* ./webrtc/src/third_party/libyuv
      export WEBRTCROOT=$(pwd)/webrtc
    '';

    postPatch = ''
      substituteInPlace live555helper/CMakeLists.txt \
        --replace-fail 'set(LIVE ''${CMAKE_BINARY_DIR}/live)' 'set(LIVE "${live555.src}")'
    '';

    extraCmakeFlags = [
      "-DWEBRTCROOT=${placeholder "$WEBRTCROOT"}/src"
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
      gn
      ninja
    ];

    enableParallelBuilding = true;

    passthru = {
      webrtc = webrtc.src;
      jank = ''
        mkdir -p ./third_party/abseil-cpp
        cp -r ${abseil-cpp.src}/* ./third_party/abseil-cpp
        mkdir -p ./third_party/jsoncpp/source
        cp -r ${jsoncpp.src}/* ./third_party/jsoncpp/source
        mkdir -p ./third_party/libyuv
        cp -r ${libyuv.src}/* ./third_party/libyuv
      '';
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
