{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.suites.desktop.addons.gnome;
in {
  options.suites.desktop.addons.gnome = with types; {
    enable = mkBoolOpt false "Enable or disable the gnome DE.";
  };

  config = mkIf cfg.enable {
    suites.desktop.addons.nautilus.enable = true;

    services = {
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome = {
          enable = true;
          extraGSettingsOverridePackages = [
            pkgs.nautilus-open-any-terminal
          ];
        };
      };
    };

    services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
    programs.dconf.enable = true;
  };
}
