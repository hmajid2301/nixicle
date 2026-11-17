{ stdenvNoCC, inputs, ... }:
stdenvNoCC.mkDerivation {
  pname = "monolisa";
  version = "0.1.0";

  # Licensed font: lives in the private nixicle-assets repo, never in this public one.
  src = "${inputs.nixicle-assets}/fonts/MonoLisa";

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp $src/*.ttf $out/share/fonts/truetype/
  '';
}
