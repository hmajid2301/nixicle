{
  options,
  config,
  lib,
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
    services = {
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      qemuGuest.enable = true;
      spice-vdagentd.enable = true;
    };
  };
}
