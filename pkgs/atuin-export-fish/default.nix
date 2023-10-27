{ lib, buildGoPackage, ... }:

buildGoPackage rec {
  name = "atuin-export-fish";
  goPackagePath = "example.com/m";

  src = ./.;

  meta = with lib; {
    description = "Used to export Atuin shell history to fish shell history file";
  };
}
