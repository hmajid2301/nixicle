{ pkgs, ... }: {
  imports = [
    ./lutris.nix
    ./steam.nix
  ];

  home.packages = with pkgs; [
    protonup-qt
    cartridges
    bottles
  ];
}
