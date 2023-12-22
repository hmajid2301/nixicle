{ inputs, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    cheat
    cht-sh
    navi
    tealdeer
  ];
}
