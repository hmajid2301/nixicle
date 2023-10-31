{ pkgs ? (import ../nixpkgs.nix) { } }: {
  monolisa = pkgs.callPackage ./monolisa { };
  codeium-ls = pkgs.callPackage ./codeium-ls.nix { };
  atuin-export-fish = pkgs.callPackage ./atuin-export-fish-history.nix { };
}
