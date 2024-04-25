{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.roles.desktop.addons.hyprland;
in {
  options.roles.desktop.addons.hyprland = with types; {
    enable = mkBoolOpt false "Enable or disable the hyprland window manager.";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.hyprland.enable = true;
    roles.desktop.addons.greetd.enable = true;
    roles.desktop.addons.xdg-portal.enable = true;
  };
}
