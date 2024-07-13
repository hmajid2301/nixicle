{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.roles.common;
in {
  imports = with inputs; [
    stylix.homeManagerModules.stylix
    catppuccin.homeManagerModules.catppuccin
  ];

  options.roles.common = {
    enable = lib.mkEnableOption "Enable common configuration";
  };

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      image = pkgs.nixicle.wallpapers.Kurzgesagt-Galaxy_2;

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
          package = pkgs.source-serif;
          name = "Source Serif";
        };

        sansSerif = {
          package = pkgs.fira;
          name = "Fira Sans";
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

    browsers.firefox.enable = true;

    system = {
      nix.enable = true;
      fonts.enable = true;
    };

    cli = {
      terminals.foot.enable = true;
      shells.fish.enable = true;
    };
    programs = {
      guis.enable = true;
      tuis.enable = true;
    };

    security = {
      sops.enable = true;
    };

    # TODO: move this to a separate module
    home.packages = with pkgs;
    with nixicle; [
      keymapp

      src-cli

      (hiPrio parallel)
      moreutils
      nvtopPackages.amd
      unzip
      gnupg

      showmethekey
    ];
  };
}
