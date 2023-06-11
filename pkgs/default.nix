{ pkgs ? (import ../nixpkgs.nix) { } }: {
  fonts = pkgs.callPackage ./fonts { };
}
