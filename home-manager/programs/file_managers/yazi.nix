{ pkgs, ... }: {
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    settings = { };
    theme = { };
  };

  home.packages = with pkgs; [
    ffmpegthumbnailer
    unar
    poppler
  ];
}
