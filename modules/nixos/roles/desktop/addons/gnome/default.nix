{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.roles.desktop.addons.gnome;
in
{
  options.roles.desktop.addons.gnome = with types; {
    enable = mkBoolOpt false "Enable or disable the gnome DE.";
  };

  config = mkIf cfg.enable {
    roles.desktop.addons.nautilus.enable = true;

    services = {
      displayManager.gdm.enable = true;
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [ pkgs.nautilus-open-any-terminal ];
      };
      xserver = {
        enable = true;
      };
    };

    services.udev.packages = with pkgs; [ gnome-settings-daemon ];
    programs.dconf.enable = true;
  };
}
