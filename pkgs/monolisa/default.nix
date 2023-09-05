#
# MonoLisa package for Nix.
#
{ pkgs ? import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/4fe8d07066f6ea82cda2b0c9ae7aee59b2d241b3.tar.gz";
      sha256 = "sha256:06jzngg5jm1f81sc4xfskvvgjy5bblz51xpl788mnps1wrkykfhp";
    })
    { }
,
}:
pkgs.stdenv.mkDerivation rec {
  pname = "monolisa";
  version = "0.1.0";

  src = ./MonoLisa;

  installPhase = ''
    mkdir -p $out/share/fonts
    cp -R $src $out/share/fonts/truetype/
  '';
}
