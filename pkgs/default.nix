{ pkgs ? (import ../nixpkgs.nix) { } }: {
  monolisa = pkgs.callPackage ./monolisa { };
}
