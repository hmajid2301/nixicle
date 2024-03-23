{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  cmake,
  hidapi,
}:
stdenv.mkDerivation {
  name = "headsetcontrol";

  nativeBuildInputs = [pkg-config cmake hidapi];

  src = fetchFromGitHub {
    owner = "Sapd";
    repo = "HeadsetControl";
    rev = "a95a015b7aa094f5369c861ded094ecb7eb3a45b";
    sha256 = "06ms9ca86vdf0zi3x8r15rw5dgybc7cazrqqkxp42hqrfl7wwvja";
  };

  installPhase = ''
    make install
    mkdir -p $out/etc/udev/rules.d
    $out/bin/headsetcontrol -u > $out/etc/udev/rules.d/70-headsets.rules
  '';

  meta = {
    description = "a tool to control certain aspects of usb-connected headsets on linux";
    homepage = "https://github.com/Sapd/HeadsetControl";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
