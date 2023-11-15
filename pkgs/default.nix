{ pkgs ? (import ../nixpkgs.nix) { } }: {
  monolisa = pkgs.callPackage ./monolisa { };
  atuin-export-fish = pkgs.callPackage ./atuin-export-fish-history.nix { };
  headsetcontrol2 = pkgs.callPackage ./headsetcontrol.nix { };
}
