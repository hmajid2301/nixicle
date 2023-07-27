{ pkgs ? (import ../nixpkgs.nix) { } }: {
  monolisa = pkgs.callPackage ./monolisa { };
  dooit2 = pkgs.callPackage ./dooit.nix { };
  swaylock-effects2 = pkgs.callPackage ./swaylock-effects.nix { };
}
