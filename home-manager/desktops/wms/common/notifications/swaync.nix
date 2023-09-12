{ pkgs, ... }: {
  home.packages = with pkgs; [
    swaynotificationcenter
  ];
}
