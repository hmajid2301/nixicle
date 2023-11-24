{ pkgs, ... }: {

  home.packages = with pkgs; [
    fontconfig
    fira-code-nerdfont
    google-fonts
    open-sans
    zlib # workaround for #703
  ];

  fonts.fontconfig.enable = true;
}
