{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.custom.desktop.addons.hypridle;
  inherit (inputs) hypridle;
in {
  imports = [hypridle.homeManagerModules.default];

  options.custom.desktop.addons.hypridle = with types; {
    enable = mkBoolOpt false "Whether to enable the hypridle";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      # package = pkgs.hypridle;

      lockCmd = "${pkgs.swaylock-effects}/bin/swaylock -fF";
      afterSleepCmd = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";

      # 5 min lock, 10min turn the screen off, 20 min suspend
      listeners = [
        {
          timeout = 300;
          onTimeout = "${pkgs.swaylock-effects}/bin/swaylock -fF";
        }
        {
          timeout = 600;
          onTimeout = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms off";
          onResume = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
        }
        {
          timeout = 1200;
          onTimeout = "${pkgs.systemd}/bin/systemctl suspend";
          onResume = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch dpms on";
        }
      ];
    };
  };
}
