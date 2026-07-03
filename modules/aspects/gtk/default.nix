_: {
  den.aspects.gtk-theme = {
    homeManager =
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        home.sessionVariables.GTK_THEME = "Adwaita:dark";
        home.pointerCursor = lib.mkForce {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
          gtk.enable = true;
        };
      };
  };
}
