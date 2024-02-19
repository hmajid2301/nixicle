{pkgs ? (import ../nixpkgs.nix) {}}: {
  atuin-export-fish = pkgs.callPackage ./atuin-export-fish-history.nix {};
  headsetcontrol2 = pkgs.callPackage ./headsetcontrol.nix {};
  all-ways-egpu = pkgs.callPackage ./all-ways-egpu.nix {};
  copilotchat-nvim = pkgs.callPackage ./copilotchat-nvim.nix {};
  adwaita-for-steam = pkgs.callPackage ./adwaita-for-steam {};
  monolisa = pkgs.callPackage ./monolisa {};
}
