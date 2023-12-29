{
  lib,
  stdenv,
  fetchFromGitHub,
  pciutils,
  gawk,
  gnugrep,
  mount,
  umount,
}:
stdenv.mkDerivation rec {
  pname = "all-ways-egpu";
  version = "0.51.1";

  src = fetchFromGitHub {
    owner = "ewagner12";
    repo = "all-ways-egpu";
    rev = "v${version}";
    hash = "sha256-OnFufCrP8ugnpXH8FEVcInyYdIrNOn/igHckXFEpnCI=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp all-ways-egpu $out/bin/all-ways-egpu
    chmod +x $out/bin/all-ways-egpu
  '';

  postPatch = ''
    substituteInPlace all-ways-egpu \
      --replace "lspci" "${pciutils}/bin/lspci" \
      --replace "awk" "${gawk}/bin/awk" \
      --replace "mount" "${mount}/bin/mount" \
      --replace "umount" "${umount}/bin/umount" \
      --replace "grep" "${gnugrep}/bin/grep"
  '';

  meta = with lib; {
    description = "Configure eGPU as primary under Linux Wayland desktops";
    homepage = "https://github.com/ewagner12/all-ways-egpu/tree/main";
    license = licenses.mit;
    maintainers = with maintainers; [];
    mainProgram = "all-ways-egpu";
    platforms = platforms.all;
  };
}
