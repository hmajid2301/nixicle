{pkgs, ...}: {
  home.packages = with pkgs; [
    shotwell
  ];
}
