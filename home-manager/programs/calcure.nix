{ pkgs, ... }: {
  home.packages = with pkgs; [
    calcure
    vdirsyncer
  ];
}
