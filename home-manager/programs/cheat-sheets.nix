{pkgs, ...}: {
  home.packages = with pkgs; [
    cheat
    cht-sh
    navi
    tealdeer
  ];
}
