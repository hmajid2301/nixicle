{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    fontconfig
    fira-code-nerdfont
    noto-fonts-color-emoji
    google-fonts
    twitter-color-emoji
    open-sans
    zlib # workaround for #703
  ];

  fonts.fontconfig.enable = lib.mkForce true;
}
