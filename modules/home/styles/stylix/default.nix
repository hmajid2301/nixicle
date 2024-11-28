{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.styles.stylix;
in {
  imports = with inputs; [
    stylix.homeManagerModules.stylix
    catppuccin.homeManagerModules.catppuccin
  ];

  options.styles.stylix = {
    enable = lib.mkEnableOption "Enable stylix";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      # google-fonts
      open-sans
      plemoljp
    ];

    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      targets.nixvim.enable = false;

      image = pkgs.nixicle.wallpapers.earth;

      cursor = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      fonts = {
        sizes = {
          terminal = 14;
          applications = 12;
          popups = 12;
        };

        serif = {
          name = "Source Serif";
          package = pkgs.source-serif;
        };

        sansSerif = {
          name = "Noto Sans";
          package = pkgs.noto-fonts;
        };

        monospace = {
          package = pkgs.nixicle.monolisa;
          name = "MonoLisa Nerd Font";
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
      };
    };
  };
}
