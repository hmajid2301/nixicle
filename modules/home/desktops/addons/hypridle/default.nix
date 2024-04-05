{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.desktops.addons.hypridle;
  inherit (inputs) hypridle;
  hyprlock = "${pkgs.hyprlock}/bin/hyprlock";
  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  loginctl = "${pkgs.systemd}/bin/loginctl";
in {
  imports = [hypridle.homeManagerModules.default];

  options.desktops.addons.hypridle = with types; {
    enable = mkBoolOpt false "Whether to enable the hypridle";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;

      lockCmd = "pidof hyprlock || ${hyprlock}";
      beforeSleepCmd = "${hyprctl} dispatch dpms off";
      afterSleepCmd = "${hyprctl} dispatch dpms on && ${loginctl} lock-session";
      listeners = [
        {
          timeout = 300;
          onTimeout = "${loginctl} lock-session";
        }
        {
          timeout = 360;
          onTimeout = "${hyprctl} dispatch dpms off";
          onResume = "${hyprctl} dispatch dpms on";
        }
      ];
    };
  };
}
