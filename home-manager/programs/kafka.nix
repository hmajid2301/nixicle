{pkgs, ...}: {
  home.packages = with pkgs; [
    kaf
  ];
}
