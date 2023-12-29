{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  cmake,
  hidapi,
}:
stdenv.mkDerivation rec {
  name = "headsetcontrol";

  nativeBuildInputs = [pkg-config cmake hidapi];

  src = fetchFromGitHub {
    owner = "Sapd";
    repo = "HeadsetControl";
    rev = "1194d6003599b7874d8f576554fa3b698090f5a2";
    sha256 = "sha256-oaRBsi/PEkpojejShAorHZOuiqzFcYkcIZdEuh8Pda0=";
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
