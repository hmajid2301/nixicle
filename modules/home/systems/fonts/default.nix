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
    enable = mkBoolOpt false "Whether or not to manage fonts";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      helvetica-neue-lt-std
      fontconfig
      fira-code-nerdfont
      fira-sans
      noto-fonts
      noto-fonts-color-emoji
      twitter-color-emoji
      google-fonts
      open-sans
      zlib
    ];

    # fonts.fontconfig.enable = lib.mkForce true;
    # fonts.fontconfig.defaultFonts = {
    #   serif = ["Source Serif" "Noto Color Emoji"];
    #   sansSerif = ["Noto Sans" "Noto Color Emoji"];
    #   monospace = ["MonoLisa Nerd Font" "Noto Color Emoji"];
    #   emoji = ["Noto Color Emoji"];
    # };
  };
}
