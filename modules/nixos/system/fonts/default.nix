{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.system.fonts;
in {
  options.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = mkOpt (listOf package) [] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = false;
      fontDir.enable = true;
      packages = with pkgs;
        [
          (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
          fira
          fira-go
          noto-fonts-color-emoji
          helvetica-neue-lt-std
          source-serif
          ubuntu_font_family
          jetbrains-mono
          open-sans
        ]
        ++ cfg.fonts;

      fontconfig = {
        antialias = true;
        defaultFonts = {
          serif = ["Source Serif" "Noto Color Emoji"];
          sansSerif = ["Fira Sans" "FiraGO" "Noto Color Emoji"];
          monospace = ["MonoLisa Nerd Font" "Noto Color Emoji"];
          emoji = ["Noto Color Emoji"];
        };
        enable = true;
        hinting = {
          autohint = false;
          enable = true;
          style = "slight";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "light";
        };
      };
    };
  };
}
