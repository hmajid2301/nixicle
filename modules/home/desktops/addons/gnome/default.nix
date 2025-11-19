{delib, ...}:
delib.module {
  name = "desktops-addons-gnome";

  options.desktops.addons.gnome = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  let
    cfg = config.desktops.addons.gnome;
  in
  mkIf cfg.enable {
    xdg = {
      mime.enable = true;
      systemDirs.data = [
        "${config.home.homeDirectory}/.nix-profile/share/applications"
        "${config.home.homeDirectory}/state/nix/profile/share/applications"
      ];
    };
    targets.genericLinux.enable = true;

    dconf.settings = {
      "org/gnome/desktop/thumbnailers" = {
        disable-all = false;
      };

      "org/gnome/desktop/thumbnail-cache" = {
        maximum-age = -1;
        maximum-size = -1;
      };
    };
  };
}
