{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.desktops.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      windowrule = [
        "float, bitwarden"
      ];

      windowrulev2 = [
        "idleinhibit fullscreen, class:^(firefox)$"
      ];
    };
  };
}
