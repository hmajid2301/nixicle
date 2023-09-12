{ config
, pkgs
, inputs
, ...
}:
let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

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
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  home.sessionVariables.GTK_THEME = "${config.colorscheme.slug}";
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.frappeLight;
    name = "Catppuccin-Frappe-Light-Cursors";
    size = 50;
    x11.enable = true;
    gtk.enable = true;
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Catppuccin-Frappe-Light-Cursors";
    XCURSOR_SIZE = "32";
  };
}
