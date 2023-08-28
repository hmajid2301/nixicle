{pkgs ? (import ../nixpkgs.nix) {}}: {
  monolisa = pkgs.callPackage ./monolisa {};
  dooit2 = pkgs.callPackage ./dooit.nix {};
  catppuccin-lemmy = pkgs.callPackage ./catppuccin-lemmy.nix {};
  swaylock-effects2 = pkgs.callPackage ./swaylock-effects.nix {};
  hmts-nvim = pkgs.callPackage ./vim/hmts.nix {};
  maximize-nvim = pkgs.callPackage ./vim/maximize.nix {};
  codeium-nvim = pkgs.callPackage ./vim/codeium-nvim.nix {};
  codeium-ls = pkgs.callPackage ./codeium-ls.nix {};
}
