{ config, pkgs, inputs, ... }:

let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
rec {
  gtk = {
    enable = true;
    font = {
      name = config.fontProfiles.regular.family;
      size = 12;
    };

    # TODO: colorscheme
    theme = {
      name = "Catppuccin-Frappe-Compact-Pink-dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "pink" ];
        size = "compact";
        tweaks = [ "rimless" "black" ];
        variant = "frappe";
      };
    };

    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Catppuccin-Frappe-Dark";
    };
  };

  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.frappeLight;
    name = "Catppuccin-Frappe-Light-Cursors";
    size = 50;
    x11.enable = true;
    gtk.enable = true;
  };
}

