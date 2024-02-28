{
  pkgs,
  config,
  ...
}: let
  inherit (config.colorscheme) colors;
in {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      show-failed-attempts = true;
      screenshots = true;
      clock = true;

      indicator = true;
      indicator-radius = 350;
      indicator-thickness = 5;

      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      fade-in = 0.2;

      font = "${config.my.settings.fonts.monospace}";
      ring-color = "${colors.base02}";
      inside-wrong-color = "${colors.base08}";
      ring-wrong-color = "${colors.base08}";
      key-hl-color = "${colors.base0B}";
      bs-hl-color = "${colors.base08}";
      ring-ver-color = "${colors.base09}";
      inside-ver-color = "${colors.base09}";
      inside-color = "${colors.base01}";
      text-color = "${colors.base07}";
      text-clear-color = "${colors.base01}";
      text-ver-color = "${colors.base01}";
      text-wrong-color = "${colors.base01}";
      text-caps-lock-color = "${colors.base07}";
      inside-clear-color = "${colors.base0C}";
      ring-clear-color = "${colors.base0C}";
      inside-caps-lock-color = "${colors.base09}";
      ring-caps-lock-color = "${colors.base02}";
      separator-color = "${colors.base02}";
    };
  };

  services.swayidle = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock-effects}/bin/swaylock -fF";
      }
      {
        event = "lock";
        command = "${pkgs.swaylock-effects}/bin/swaylock -fF";
      }
    ];
    timeouts = [
      {
        timeout = 600;
        command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
        resumeCommand = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
      }
      {
        timeout = 610;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
    ];
  };
}
