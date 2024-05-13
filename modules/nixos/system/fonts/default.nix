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
          fira
          fira-go
          fira-code-nerdfont
          noto-fonts-emoji
          source-serif
          ubuntu_font_family
          jetbrains-mono
          open-sans
          (joypixels.override {acceptLicense = true;})
        ]
        ++ cfg.fonts;

      fontconfig = {
        antialias = true;
        defaultFonts = {
          serif = ["Source Serif"];
          sansSerif = ["Fira Sans" "FiraGO"];
          monospace = ["MonoLisa Nerd Font" "FiraCode Nerd Font Mono" "SauceCodePro Nerd Font Mono" "Noto Color Emoji"];
          emoji = ["Joypixels" "Noto Color Emoji"];
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
