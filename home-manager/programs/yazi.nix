{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    imagemagick
    ffmpegthumbnailer
    fontpreview
    unar
    poppler
    unar
  ];
}
