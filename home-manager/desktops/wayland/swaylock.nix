{ inputs, pkgs, config, ... }:
let inherit (config.colorscheme) colors;
in
{

  # TODO: move to home.nix
  nixpkgs.overlays = [
    inputs.nur.overlay
  ];

  home.packages = with pkgs; [
    nur.repos."999eagle".swayaudioidleinhibit
  ];

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects2;
    settings = {
      # Show number of failed attempts
      show-failed-attempts = true;

      # Take a screenshot of the current desktop
      screenshots = true;

      # Display the current time
      clock = true;
      timestr = "%I:%M:%S %p";
      datestr = "%A %d %B %Y";

      # Display an idle indicator
      indicator = true;
      indicator-idle-visible = true;
      indicator-radius = 200;
      indicator-thickness = 7;

      # Blur background
      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      fade-in = 0.2;

      ring-color = "#${colors.base02}";
      inside-wrong-color = "#${colors.base08}";
      ring-wrong-color = "#${colors.base08}";
      key-hl-color = "#${colors.base0B}";
      bs-hl-color = "#${colors.base08}";
      ring-ver-color = "#${colors.base09}";
      inside-ver-color = "#${colors.base09}";
      inside-color = "#${colors.base01}";
      text-color = "#${colors.base07}";
      text-clear-color = "#${colors.base01}";
      text-ver-color = "#${colors.base01}";
      text-wrong-color = "#${colors.base01}";
      text-caps-lock-color = "#${colors.base07}";
      inside-clear-color = "#${colors.base0C}";
      ring-clear-color = "#${colors.base0C}";
      inside-caps-lock-color = "#${colors.base09}";
      ring-caps-lock-color = "#${colors.base02}";
      separator-color = "#${colors.base02}";
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