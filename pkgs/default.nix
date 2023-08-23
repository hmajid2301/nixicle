{pkgs ? (import ../nixpkgs.nix) {}}: {
  monolisa = pkgs.callPackage ./monolisa {};
  dooit2 = pkgs.callPackage ./dooit.nix {};
  catppuccin-lemmy = pkgs.callPackage ./catppuccin-lemmy.nix {};
  swaylock-effects2 = pkgs.callPackage ./swaylock-effects.nix {};
  hmts-nvim = pkgs.callPackage ./vim/hmts.nix {};
  windex-nvim = pkgs.callPackage ./vim/windex.nix {};
}
