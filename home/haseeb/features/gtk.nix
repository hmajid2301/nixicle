{ config, pkgs, inputs, ... }:

let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
rec {
  home.packages = [ pkgs.dconf pkgs.gnome.dconf-editor ];
  gtk = {
    enable = true;
    #font = {
    #  name = config.fontProfiles.regular.family;
    #  size = 12;
    #};
    theme = {
      name = "Catppuccin-Frappe-Compact-Pink-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "pink" ];
        size = "compact";
        #tweaks = [ "rimless" "black" ];
        variant = "frappe";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        accent = "lavender";
        flavor = "frappe";
      };
    };

    cursorTheme = {
      name = "Catppuccin-Frappe-Dark";
    };

  };

  home.pointerCursor = {
    package = pkgs.catppuccin-cursors;
    name = "Catppuccin-Frappe-Red";
    size = 16;
  };
}

