{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.suites.desktop.addons.hyprland;
in {
  options.suites.desktop.addons.hyprland = with types; {
    enable = mkBoolOpt false "Enable or disable the hyprland window manager.";
  };

  config = mkIf cfg.enable {
    programs.hyprland.enable = true;
    suites.desktop.addons.greetd.enable = true;
    suites.desktop.addons.xdg-portal.enable = true;
  };
}
