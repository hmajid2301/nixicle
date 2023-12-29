{pkgs, ...}: {
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    fira-code-nerdfont
    roboto
    ubuntu_font_family
    oxygenfonts
    cantarell-fonts
    open-sans
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];
}
