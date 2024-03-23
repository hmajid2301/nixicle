{stdenv, ...}:
stdenv.mkDerivation {
  pname = "monolisa";
  version = "0.1.0";

  src = ./MonoLisa;

  installPhase = ''
    mkdir -p $out/share/fonts
    cp -R $src $out/share/fonts/truetype/
  '';
}
