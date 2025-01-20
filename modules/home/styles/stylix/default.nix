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
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      nerd-fonts.symbols-only
      open-sans
    ];

    # TODO: Possible to use stylix instead?
    catppuccin.flavor = "mocha";
    catppuccin.fish.enable = true;

    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      targets.nixvim.enable = false;

      iconTheme = {
        enable = true;
        package = pkgs.catppuccin-papirus-folders.override {
          flavor = "mocha";
          accent = "lavender";
        };
        dark = "Papirus-Dark";
      };

      targets = {
        firefox = {
          firefoxGnomeTheme.enable = true;
          profileNames = ["Default"];
        };
      };

      image = pkgs.nixicle.wallpapers.nixppuccin;

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
          name = "MonoLisa";
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
      };
    };
  };
}
