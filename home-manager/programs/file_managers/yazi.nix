{ pkgs, ... }: {
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    ffmpegthumbnailer
    unar
    poppler
  ];
}
