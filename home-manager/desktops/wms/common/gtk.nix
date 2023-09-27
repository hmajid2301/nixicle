{ config
, pkgs
, inputs
, ...
}:
let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
in
{
  # TODO: nix colors ? 
  xdg.configFile."gtk-4.0/gtk.css".text =
    ''
      @define-color accent_color rgb(116, 199, 236);
      @define-color accent_bg_color rgb(137, 180, 250);
      @define-color accent_fg_color rgb(17, 17, 27);
      @define-color destructive_color rgb(238, 153, 160);
      @define-color destructive_bg_color rgb(237, 135, 150);
      @define-color destructive_fg_color rgb(17, 17, 27);
      @define-color success_color rgb(166, 218, 149);
      @define-color success_bg_color rgb(139, 213, 202);
      @define-color success_fg_color rgb(17, 17, 27);
      @define-color warning_color rgb(245, 169, 127);
      @define-color warning_bg_color rgb(238, 212, 159);
      @define-color warning_fg_color rgb(17, 17, 27);
      @define-color error_color rgb(238, 153, 160);
      @define-color error_bg_color rgb(237, 135, 150);
      @define-color error_fg_color rgb(17, 17, 27);
      @define-color window_bg_color rgb(30, 30, 46);
      @define-color window_fg_color rgb(205, 214, 244);
      @define-color view_bg_color rgb(24, 24, 37);
      @define-color view_fg_color rgb(205, 214, 244);
      @define-color headerbar_bg_color rgb(17, 17, 27);
      @define-color headerbar_fg_color rgb(205, 214, 244);
      @define-color headerbar_border_color rgb(49, 50, 68);
      @define-color headerbar_backdrop_color @window_bg_color;
      @define-color headerbar_shade_color rgba(0, 0, 0, 0.36);
      @define-color card_bg_color rgb(24, 24, 37);
      @define-color card_fg_color rgb(205, 214, 244);
      @define-color card_shade_color rgba(0, 0, 0, 0.36);
      @define-color dialog_bg_color rgb(24, 24, 37);
      @define-color dialog_fg_color rgb(205, 214, 244);
      @define-color popover_bg_color rgb(24, 24, 37);
      @define-color popover_fg_color rgb(205, 214, 244);
      @define-color shade_color rgba(0,0,0,0.36);
      @define-color scrollbar_outline_color rgba(0,0,0,0.5);
      @define-color blue_1 #99c1f1;
      @define-color blue_2 #62a0ea;
      @define-color blue_3 #3584e4;
      @define-color blue_4 #1c71d8;
      @define-color blue_5 #1a5fb4;
      @define-color green_1 #8ff0a4;
      @define-color green_2 #57e389;
      @define-color green_3 #33d17a;
      @define-color green_4 #2ec27e;
      @define-color green_5 #26a269;
      @define-color yellow_1 #f9f06b;
      @define-color yellow_2 #f8e45c;
      @define-color yellow_3 #f6d32d;
      @define-color yellow_4 #f5c211;
      @define-color yellow_5 #e5a50a;
      @define-color orange_1 #ffbe6f;
      @define-color orange_2 #ffa348;
      @define-color orange_3 #ff7800;
      @define-color orange_4 #e66100;
      @define-color orange_5 #c64600;
      @define-color red_1 #f66151;
      @define-color red_2 #ed333b;
      @define-color red_3 #e01b24;
      @define-color red_4 #c01c28;
      @define-color red_5 #a51d2d;
      @define-color purple_1 #dc8add;
      @define-color purple_2 #c061cb;
      @define-color purple_3 #9141ac;
      @define-color purple_4 #813d9c;
      @define-color purple_5 #613583;
      @define-color brown_1 #cdab8f;
      @define-color brown_2 #b5835a;
      @define-color brown_3 #986a44;
      @define-color brown_4 #865e3c;
      @define-color brown_5 #63452c;
      @define-color light_1 #ffffff;
      @define-color light_2 #f6f5f4;
      	'';
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
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "blue";
      };
      name = "Papirus-Dark";
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
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
