{pkgs ? (import ../nixpkgs.nix) {}}: {
  headsetcontrol2 = pkgs.callPackage ./headsetcontrol.nix {};
  monolisa = pkgs.callPackage ./monolisa {};
}
