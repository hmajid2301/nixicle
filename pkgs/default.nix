{ pkgs ? (import ../nixpkgs.nix) { } }: {
  atuin-export-fish = pkgs.callPackage ./atuin-export-fish-history.nix { };
  headsetcontrol2 = pkgs.callPackage ./headsetcontrol.nix { };
  keymapp = pkgs.callPackage ./keymapp { };
  all-ways-egpu = pkgs.callPackage ./all-ways-egpu.nix { };
  wezterm-nightly = pkgs.callPackage ./wezterm-nightly { };
}
