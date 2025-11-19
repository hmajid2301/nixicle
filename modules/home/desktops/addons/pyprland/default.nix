{delib, ...}:
delib.module {
  name = "desktops-addons-pyprland";

  options.desktops.addons.pyprland = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  let
    cfg = config.desktops.addons.pyprland;
  in
  mkIf cfg.enable {
    xdg.configFile."hypr/pyprland.toml".source = ./pyprland.toml;

    home = {
      packages = with pkgs; [pyprland];
    };
  };
}
