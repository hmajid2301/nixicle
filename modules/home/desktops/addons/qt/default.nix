{delib, ...}:
delib.module {
  name = "desktops-addons-qt";

  options.desktops.addons.qt = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  let
    cfg = config.desktops.addons.qt;
  in
  mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
