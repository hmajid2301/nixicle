{ config, lib, pkgs, ... }:
with lib;
with lib.nixicle;
let cfg = config.roles.desktop.addons.xdg-portal;
in {
  options.roles.desktop.addons.xdg-portal = with types; {
    enable = mkBoolOpt false "Whether or not to add support for xdg portal.";
  };

  config = mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
    };
  };
}
