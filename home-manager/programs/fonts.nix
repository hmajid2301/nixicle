{ pkgs, ... }: {

  home.packages = with pkgs; [
    fontconfig
    google-fonts
    open-sans
    zlib # workaround for #703
  ];

  fonts.fontconfig.enable = true;
}
