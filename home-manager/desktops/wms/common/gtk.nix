{ config
, pkgs
, inputs
, ...
}:
let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
{
  gtk = {
    enable = true;
    font = {
      name = config.my.settings.fonts.regular;
      size = 12;
    };

    theme = {
      name = "${config.colorscheme.slug}";
      package = gtkThemeFromScheme { scheme = config.colorscheme; };
    };

    iconTheme = {
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "blue";
      };
      name = "Papirus-Dark";
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };
  qt = {
    enable = true;
    platformTheme = "qtct";
  };


  home.sessionVariables.GTK_THEME = "${config.colorscheme.slug}";
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.mochaLight;
    name = "Catppuccin-Mocha-Light-Cursors";
    size = 32;
    x11.enable = true;
    gtk.enable = true;
  };

  # home.sessionVariables = {
  #   XCURSOR_THEME = "Catppuccin-Mocha-Light-Cursors";
  #   XCURSOR_SIZE = "24";
  # };
}
