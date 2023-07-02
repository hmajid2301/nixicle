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

    theme = {
      name = "${config.colorscheme.slug}";
      package = gtkThemeFromScheme { scheme = config.colorscheme; };
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
    size = 32;
    x11.enable = true;
    gtk.enable = true;
  };
}

