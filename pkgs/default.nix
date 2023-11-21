{ pkgs ? (import ../nixpkgs.nix) { } }: {
  atuin-export-fish = pkgs.callPackage ./atuin-export-fish-history.nix { };
  headsetcontrol2 = pkgs.callPackage ./headsetcontrol.nix { };
}
